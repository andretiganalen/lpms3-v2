# frozen_string_literal: true

# LPMS3: Eksekusi Item Pengadaan berlandaskan Budget, tiga sub-fase:
#   1. PR      — menerbitkan Purchase Requisition (wajib bersandar pada Budget; tidak boleh melampaui anggaran)
#   2. Buyer   — Buyer memproses sampai terbit kontrak (rekanan, No. PO/Kontrak, masa berlaku)
#   3. Selesai — menyelesaikan item kontrak sesuai daftar milestone (anak Milestone) sampai terbit Berita Acara penagihan
# Pipeline = status tipe "Item Pengadaan". Bagian pantau murni baca; gerbang (gate) menegakkan aturan saat disimpan.
module OpenProject::Lpms3
  module Procurement
    TYPE = "Item Pengadaan"
    STAGES = ["Rencana", "PR", "Proses Pengadaan", "PO/Kontrak", "Pengiriman", "GR/SES", "Selesai"].freeze
    SUBS = { "pr" => (0..1), "buyer" => (2..3), "penyelesaian" => (4..6) }.freeze
    F = {
      pr: "No. PR", po: "No. PO", vendor: "Rekanan", value_idr: "Nilai pengadaan (IDR)", need: "Tanggal dibutuhkan",
      contract: "No. Kontrak", contract_date: "Tanggal kontrak", contract_end: "Tanggal berakhir kontrak",
      contract_value: "Nilai kontrak", contract_cur: "Mata uang kontrak", gr: "No. GR/SES", gr_date: "Tanggal GR/SES",
      ba: "No. BA penagihan", ba_date: "Tanggal BA penagihan"
    }.freeze
    EXPIRY_DAYS = 30
    I_PR = 1
    I_CONTRACT = 3
    I_DELIVERY = 4
    I_GR = 5
    I_DONE = 6
    SEVERITY = { no_budget: :high, over_budget: :high, missing_pr: :high, no_value: :medium,
                 missing_po: :high, missing_vendor: :high, overdue_need: :high, contract_expired: :high,
                 contract_expiring: :medium, no_end_date: :medium,
                 no_milestones: :medium, milestones_open: :high, missing_gr: :medium, missing_ba: :high }.freeze
    # temuan relevan per sub-fase (untuk ringkasan dan filter)
    SUB_FINDINGS = {
      "pr" => %i[no_budget over_budget missing_pr no_value overdue_need],
      "buyer" => %i[missing_po missing_vendor contract_expired contract_expiring no_end_date overdue_need],
      "penyelesaian" => %i[no_milestones milestones_open missing_gr missing_ba contract_expired]
    }.freeze

    Item = Struct.new(:wp, :stage, :stage_index, :v, :findings, :value_base, :value_note, :milestones, :budget, keyword_init: true) do
      def milestones_done = milestones.count { _1.status&.is_closed? }
      def milestones_open = milestones.size - milestones_done
    end

    module_function

    def stage_index(name) = STAGES.index(name) || 0

    def sub_of(index) = SUBS.find { |_, r| r.cover?(index) }&.first

    def type = ::Type.find_by(name: TYPE)

    def cf_map = ::WorkPackageCustomField.where(name: F.values).to_h { |c| [c.name, c] }

    def date(str) = (Date.iso8601(str.to_s) rescue nil)

    def values_from_stored(wp, cfs)
      F.to_h { |k, name| [k, (cf = cfs[name]) ? wp.custom_values.find { |cv| cv.custom_field_id == cf.id }&.value.presence : nil] }
    end

    def values_from_memory(wp, cfs)
      F.to_h { |k, name| [k, (cf = cfs[name]) ? wp.custom_field_values.find { |cv| cv.custom_field_id == cf.id }&.value.presence : nil] }
    end

    def milestones_of(wp, ms_type_ids) = wp.children.select { ms_type_ids.include?(_1.type_id) }

    # Item beserta temuannya untuk scope WorkPackage (sudah dibatasi hak akses oleh pemanggil).
    def items(scope, on: Date.current)
      t = type
      return [] unless t

      cfs = cf_map
      ms_ids = ::Type.where(is_milestone: true).pluck(:id)
      list = scope.where(type_id: t.id).includes(:status, :project, :custom_values, :budget, children: :status).order(:project_id, :id).to_a
      list.map do |wp|
        v = values_from_stored(wp, cfs)
        idx = stage_index(wp.status&.name)
        it = Item.new(wp:, stage: STAGES[idx], stage_index: idx, v:, findings: [], milestones: milestones_of(wp, ms_ids), budget: wp.budget)
        compute_value!(it, on)
        evaluate!(it, on)
        it
      end
    end

    def evaluate!(it, on)
      v = it.v
      i = it.stage_index
      f = it.findings
      # Sub-fase 1: PR di atas Budget
      f << :no_budget if i >= I_PR && it.budget.nil?
      f << :missing_pr if i >= I_PR && v[:pr].blank?
      f << :no_value if i >= I_PR && it.value_base.nil? && it.value_note.nil?
      f << :overdue_need if (need = date(v[:need])) && need < on && i < I_GR
      # Sub-fase 2: Buyer sampai kontrak
      f << :missing_po if i >= I_CONTRACT && v[:po].blank? && v[:contract].blank?
      f << :missing_vendor if i >= I_CONTRACT && v[:vendor].blank?
      end_date = date(v[:contract_end])
      f << :no_end_date if i >= I_CONTRACT && i < I_DONE && v[:contract].present? && end_date.nil?
      f << :contract_expired if end_date && end_date < on && i < I_DONE
      f << :contract_expiring if end_date && end_date >= on && end_date <= on + EXPIRY_DAYS && i < I_DONE
      # Sub-fase 3: milestone sampai Berita Acara
      f << :no_milestones if i >= I_DELIVERY && it.milestones.empty?
      f << :milestones_open if i >= I_DONE && it.milestones_open.positive?
      f << :missing_gr if i >= I_GR && v[:gr].blank?
      all_done = it.milestones.any? && it.milestones_open.zero?
      f << :missing_ba if (i >= I_DONE || (i >= I_DELIVERY && all_done)) && v[:ba].blank?
    end

    # Nilai dalam mata uang dasar: Nilai kontrak + mata uang bila ada, selain itu Nilai pengadaan (IDR).
    def compute_value!(it, on)
      v = it.v
      amount = v[:contract_value] || v[:value_idr]
      return if amount.blank?

      cur = v[:contract_value] ? (v[:contract_cur].presence || "IDR").to_s.upcase : "IDR"
      base = ::OpenProject::Lpms3::Fx.base&.code || "IDR"
      conv = ::OpenProject::Lpms3::Fx.convert(amount.to_s.tr(",", "."), cur, base, on)
      conv ? it.value_base = conv : it.value_note = :rate_missing
    rescue ArgumentError
      it.value_note = :invalid
    end

    # Komitmen (nilai item pada tahap PR ke atas) per Budget.
    def committed(items) = items.select { _1.budget && _1.stage_index >= I_PR && _1.value_base }.group_by(&:budget).transform_values { |l| l.sum(&:value_base) }

    # Baris Budget: rencana, komitmen item, sisa, terpakai. Sudah dalam mata uang dasar (= mata uang Budget).
    def budget_rows(items, project: nil)
      budgets = ::Budget.where(id: items.filter_map { _1.budget&.id }.uniq)
      budgets = budgets.or(::Budget.where(project_id: project.id)) if project
      com = committed(items)
      budgets.order(:project_id, :id).map do |b|
        plan = b.budget
        c = com.find { |bb, _| bb.id == b.id }&.last || 0
        { budget: b, plan:, committed: c, remaining: plan - c, spent: b.spent, over: c > plan }
      end
    end

    def over_budget_ids(items) = committed(items).select { |b, c| c > b.budget }.keys.map(&:id)

    def summary(items)
      by_stage = STAGES.to_h { |s| [s, items.select { _1.stage == s }] }
      findings = Hash.new(0)
      items.each { |it| it.findings.each { |c| findings[c] += 1 } }
      over = over_budget_ids(items)
      items.each { |it| (it.findings << :over_budget; findings[:over_budget] += 1) if it.budget && over.include?(it.budget.id) && it.stage_index >= I_PR }
      { by_stage:, findings:, total: items.size, value_base: items.sum { |it| it.value_base || 0 },
        flagged: items.count { _1.findings.any? } }
    end

    # ---- Gerbang: dipanggil saat Item Pengadaan disimpan. Mengembalikan [[kode, opsi]] pelanggaran. ----
    def gate(wp)
      return [] unless wp.type_id && wp.type_id == type&.id
      return [] unless wp.new_record? || wp.status_id_changed? || wp.budget_id_changed?

      cfs = cf_map
      v = values_from_memory(wp, cfs)
      idx = stage_index(wp.status&.name)
      errs = []
      if idx >= I_PR
        errs << [:budget_required] if wp.budget_id.blank?
        errs << [:pr_required] if v[:pr].blank?
        if wp.budget
          it = Item.new(wp:, v:, stage_index: idx, findings: [], milestones: [])
          compute_value!(it, Date.current)
          errs << [:value_required] if it.value_base.nil? && it.value_note.nil?
          errs << [:rate_missing] if it.value_note == :rate_missing
          if it.value_base
            others = items(::WorkPackage.where(budget_id: wp.budget_id).where.not(id: wp.id)).select { _1.stage_index >= I_PR && _1.value_base }
            total = others.sum(&:value_base) + it.value_base
            plan = wp.budget.budget
            errs << [:over_budget, { plan: plan.round(0).to_s, total: total.round(0).to_s }] if total > plan
          end
        end
      end
      errs << [:vendor_required] if idx >= I_CONTRACT && v[:vendor].blank?
      errs << [:contract_required] if idx >= I_CONTRACT && v[:po].blank? && v[:contract].blank?
      if idx >= I_DONE
        ms_ids = ::Type.where(is_milestone: true).pluck(:id)
        ms = wp.persisted? ? milestones_of(wp, ms_ids) : []
        errs << [:milestones_required] if ms.empty?
        errs << [:milestones_open, { count: ms.count { !_1.status&.is_closed? }.to_s }] if ms.any? { !_1.status&.is_closed? }
        errs << [:ba_required] if v[:ba].blank?
      end
      errs
    end
  end
end
