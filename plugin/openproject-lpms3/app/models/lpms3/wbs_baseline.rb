# frozen_string_literal: true

module Lpms3
  # Baseline WBS otomatis (1.41, docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md §6).
  #  - Setiap perubahan editor WBS yang menyentuh atribut baseline (struktur/nomor, tasks, weight, tanggal rencana,
  #    harga) memperbarui satu versi DRAFT. Progres (% Complete, tanggal aktual) tidak membuat draft.
  #  - Sebelum ada baseline aktif, draft = Baseline 0 (Kick-Off) dan ditetapkan Pimpro/Project Analis.
  #  - Sesudahnya, draft versi berikutnya otomatis membawa work package "Change Request" (BFR-001) berstatus Draft.
  #    CR Disetujui → draft aktif (yang lama SUPERSEDED). CR Ditolak → draft REJECTED.
  #  - Selama CR sudah diajukan (status selain Draft), perubahan rencana ditolak sampai CR diputuskan.
  #  - Aktivitas yang mencapai 100 % dibekukan (lpms3.wbs_done_snapshot); baseline berikutnya memakai nilai rekamnya.
  module WbsBaseline
    CR_TYPE = "Change Request"
    CR_EDITABLE = %w[New Draft].freeze
    CR_APPROVED = "Disetujui"
    CR_REJECTED = "Ditolak"
    PIMPRO_ROLE = "Pimpro"
    KICKOFF_FIELD = "Tanggal Kick-Off (Baseline 0)"
    FIELD_LABELS = { tasks: "Tasks", level: "Level", weight: "Weight", date_plan_start: "Date Plan Start",
                     date_plan_finish: "Date Plan Finish", harga_pekerjaan: "Harga Pekerjaan" }.freeze
    SUMMARY_LIMIT = 60

    module_function

    # ---------- Snapshot rencana ----------

    # Atribut baseline seluruh node saat ini; aktivitas beku memakai nilai rekam saat selesai.
    def current_items(project)
      rows = Wbs.rows(project)
      snaps = WbsDoneSnapshot.where(project_id: project.id).index_by(&:wbs_node_id)
      rows.map do |r|
        n = r[:node]
        s = snaps[n.id]
        src = s || n
        { wbs_node_id: n.id, parent_wbs_node_id: n.parent_id, wbs_code: n.wbs_code, tasks: src.tasks, level: n.level,
          weight: (src.weight || 0).to_d.round(9), weigh_factor: n.weigh_factor,
          date_plan_start: src.date_plan_start, date_plan_finish: src.date_plan_finish,
          harga_pekerjaan: n.harga_pekerjaan, sort_order: n.sort_order, is_frozen: s.present? }
      end
    end

    def stored_items(baseline)
      return [] unless baseline

      BaselineItem.where(baseline_id: baseline.id).map { |i| i.attributes.symbolize_keys }
    end

    # Kunci = nomor WBS (struktur), nilai = atribut yang dibandingkan.
    def signature(items)
      items.to_h do |i|
        [i[:wbs_code], { tasks: i[:tasks].to_s, level: i[:level], weight: i[:weight].to_f.round(6),
                         date_plan_start: i[:date_plan_start], date_plan_finish: i[:date_plan_finish],
                         harga_pekerjaan: i[:harga_pekerjaan]&.to_f }]
      end
    end

    def diff(old_items, new_items)
      a = signature(old_items)
      b = signature(new_items)
      names = new_items.to_h { |i| [i[:wbs_code], i[:tasks]] }.merge(old_items.to_h { |i| [i[:wbs_code], i[:tasks]] }) { |_, n, _| n }
      # Tanggal baris induk diturunkan dari anaknya; cukup dilaporkan pada aktivitas.
      summary_codes = (old_items + new_items).then do |all|
        pids = all.filter_map { |i| i[:parent_wbs_node_id] }.to_set
        all.select { |i| pids.include?(i[:wbs_node_id]) }.map { |i| i[:wbs_code] }.to_set
      end
      changed = (a.keys & b.keys).filter_map do |code|
        fields = a[code].keys.reject { |k| a[code][k] == b[code][k] }
        fields -= %i[date_plan_start date_plan_finish] if summary_codes.include?(code)
        [code, fields.map { |f| [f, a[code][f], b[code][f]] }] if fields.any?
      end
      { added: (b.keys - a.keys).map { |c| [c, names[c]] }, removed: (a.keys - b.keys).map { |c| [c, names[c]] }, changed: }
    end

    def summary_text(d)
      lines = d[:added].map { |c, t| "Ditambah: #{c} #{t}" } + d[:removed].map { |c, t| "Dihapus: #{c} #{t}" }
      lines += d[:changed].map do |code, fields|
        "Diubah: #{code} — " + fields.map { |f, x, y| "#{FIELD_LABELS[f]} #{fmt(f, x)} → #{fmt(f, y)}" }.join("; ")
      end
      return "Tidak ada perubahan." if lines.empty?

      extra = lines.size - SUMMARY_LIMIT
      lines = lines.first(SUMMARY_LIMIT)
      lines << "… dan #{extra} perubahan lain." if extra.positive?
      lines.join("\n")
    end

    def fmt(field, v)
      return "—" if v.nil? || v == ""

      case field
      when :weight then format("%.4f %%", v.to_f * 100)
      when :harga_pekerjaan then format("%.2f", v.to_f)
      else v.to_s
      end
    end

    # ---------- Draft otomatis ----------

    # Dipanggil Wbs.mutate! setelah refresh!, di dalam transaksi + kunci proyek.
    def sync_draft!(project, actor)
      items = current_items(project)
      return nil if items.empty?

      sig = signature(items)
      active = Baseline.active_for(project)
      draft = Baseline.draft_for(project)

      if active.nil?
        draft ||= new_draft!(project, actor)
        write_items!(draft, items, actor) if signature(stored_items(draft)) != sig
        return draft
      end

      active_items = stored_items(active)
      if signature(active_items) == sig
        discard_draft!(draft) if draft && cr_editable?(draft)
        return nil
      end

      if draft && !cr_editable?(draft)
        return draft if signature(stored_items(draft)) == sig

        raise Wbs::Error, "Perubahan rencana ditahan: #{draft.label} sedang diproses lewat Change Request " \
                          "##{draft.change_request_form_id} (status #{draft.cr_status}). Tunggu keputusan CR; " \
                          "% Complete dan tanggal aktual tetap dapat diisi."
      end

      draft ||= new_draft!(project, actor)
      if signature(stored_items(draft)) != sig
        write_items!(draft, items, actor)
        draft.update_columns(change_summary: summary_text(diff(active_items, items)), updated_at: Time.current)
      end
      ensure_cr!(project, draft, actor)
      draft
    end

    def new_draft!(project, actor)
      version = (Baseline.where(project_id: project.id).maximum(:version) || -1) + 1
      Baseline.create!(project_id: project.id, version:, label: version.zero? ? "Baseline 0 (Kick-Off)" : "Baseline #{version}",
                       status: "DRAFT", is_active: false, created_by: actor&.id, updated_at: Time.current)
    end

    def write_items!(baseline, items, actor)
      BaselineItem.where(baseline_id: baseline.id).delete_all
      BaselineItem.insert_all!(items.map { |i| i.merge(baseline_id: baseline.id) }) if items.any?
      baseline.update_columns(updated_at: Time.current, created_by: baseline.created_by || actor&.id)
    end

    def cr_editable?(baseline)
      baseline.version.zero? || baseline.change_request.nil? || CR_EDITABLE.include?(baseline.cr_status)
    end

    def discard_draft!(baseline)
      wp = baseline.change_request
      BaselineItem.where(baseline_id: baseline.id).delete_all
      baseline.destroy!
      ::WorkPackages::DeleteService.new(user: ::User.system, model: wp).call if wp && CR_EDITABLE.include?(wp.status&.name)
    end

    # ---------- Change Request (BFR-001) ----------

    def cr_type(project) = project.enabled_types.find { |t| t.name == CR_TYPE }

    def pimpro_id(project)
      role = ::ProjectRole.find_by(name: PIMPRO_ROLE)
      role && ::Member.joins(:member_roles).where(project_id: project.id, member_roles: { role_id: role.id })
                      .joins(:principal).where(users: { type: "User", status: ::Principal.statuses[:active] })
                      .order(:id).pick(:user_id)
    end

    def ensure_cr!(project, draft, actor)
      return if draft.version.zero?

      type = cr_type(project)
      return unless type # panel WBS memberi peringatan

      desc = cr_description(project, draft, actor)
      note = "Draft baseline WBS diperbarui oleh #{actor&.name || 'Sistem'} (Editor WBS LPMS3)"
      if (wp = draft.change_request)
        return if wp.description.to_s == desc

        res = ::WorkPackages::UpdateService.new(user: ::User.system, model: wp).call(description: desc, journal_notes: note)
        raise Wbs::Error, "Change Request ##{wp.id} gagal diperbarui: #{res.errors.full_messages.join('; ')}" unless res.success?
      else
        draft_status = ::Status.find_by(name: "Draft")
        attrs = { project:, type:, subject: "BFR-001 #{draft.label} — #{Wbs.kode_proyek(project)}".first(255),
                  description: desc, assigned_to_id: pimpro_id(project), journal_notes: note }
        res = ::WorkPackages::CreateService.new(user: ::User.system).call(**attrs.compact)
        raise Wbs::Error, "Change Request gagal dibuat: #{res.errors.full_messages.join('; ')}" unless res.success?

        wp = res.result
        # Status awal CR selalu Draft (workflow: hanya Pimpro yang memindahkan New → Draft lewat form).
        wp.update_columns(status_id: draft_status.id) if draft_status && wp.status_id != draft_status.id
        draft.update_columns(change_request_form_id: wp.id)
      end
    end

    def cr_description(project, draft, actor)
      active = Baseline.active_for(project)
      <<~MD
        Draft baseline WBS dibuat otomatis oleh Editor WBS LPMS3. **#{draft.label}** menjadi baseline aktif setelah
        Change Request ini berstatus **Disetujui** (BFR-001); bila **Ditolak**, draft ditolak dan WBS dapat dikembalikan
        ke baseline aktif dari halaman WBS & Bobot.

        - Baseline aktif: #{active ? "#{active.label} (disetujui #{active.approved_at&.to_date})" : '—'}
        - Draft: #{draft.label}
        - Perubahan terakhir oleh: #{actor&.name || 'Sistem'}

        ### Ringkasan perubahan terhadap baseline aktif

        #{draft.change_summary.to_s.lines.map { |l| "- #{l.strip}" }.join("\n")}
      MD
    end

    # Draft baseline (versi > 0) dengan CR masih Draft di proyek tempat user berperan Pimpro: menunggu pengajuan.
    def cr_pending_for(user)
      return [] unless user&.logged?

      role = ::ProjectRole.find_by(name: PIMPRO_ROLE)
      return [] unless role

      pids = ::Member.joins(:member_roles).where(user_id: user.id, member_roles: { role_id: role.id }).pluck(:project_id)
      return [] if pids.empty?

      Baseline.draft.where(project_id: pids).where("version > 0").where.not(change_request_form_id: nil)
              .includes(:project, change_request: :status).to_a
              .select { |b| b.change_request && CR_EDITABLE.include?(b.cr_status) }
    end

    # Hook WorkPackage after_commit: status CR berubah.
    def on_cr_status_change(wp)
      return unless wp.type&.name == CR_TYPE

      baseline = Baseline.draft.find_by(change_request_form_id: wp.id)
      return unless baseline

      case wp.status&.name
      when CR_APPROVED then activate!(baseline, ::User.current)
      when CR_REJECTED then baseline.update_columns(status: "REJECTED", updated_at: Time.current)
      end
    end

    # ---------- Aktivasi ----------

    def activate!(baseline, user)
      Baseline.transaction do
        Baseline.connection.execute("SELECT pg_advisory_xact_lock(#{Wbs.lock_key(baseline.project)})")
        b = baseline.reload
        if b.draft?
          now = Time.current
          Baseline.active.where(project_id: b.project_id).update_all(is_active: false, status: "SUPERSEDED", updated_at: now)
          b.update_columns(status: "ACTIVE", is_active: true, approved_by: user&.logged? ? user.id : nil, approved_at: now, updated_at: now)
          build_scurve!(b)
          set_kickoff_date!(b.project, now.to_date) if b.version.zero?
        end
        b
      end
    end

    # Baseline 0 ditetapkan Pimpro/Project Analis (tanpa CR). Seluruh aktivitas wajib bertanggal rencana dan Σ bobot sah.
    def tetapkan_baseline0!(project, actor)
      raise Wbs::Error, "Hanya Pimpro/Project Analis yang dapat menetapkan baseline." unless Wbs.can_edit?(actor, project)
      raise Wbs::Error, "Baseline aktif sudah ada; perubahan berikutnya lewat Change Request." if Baseline.active_for(project)

      Wbs.mutate!(project, actor) do
        rows = Wbs.rows(project)
        acts = rows.select { |r| r[:leaf] && !r[:node].root? }
        raise Wbs::Error, "WBS belum punya aktivitas." if acts.empty?

        tanpa = acts.select { |r| r[:node].date_plan_start.nil? || r[:node].date_plan_finish.nil? }
        raise Wbs::Error, "#{tanpa.size} aktivitas belum bertanggal rencana (mis. #{tanpa.first[:node].wbs_code})." if tanpa.any?

        bad = rows.reject { |r| r[:leaf] }.find { |r| (r[:children].sum { |k| k.weigh_factor.to_f } - 1).abs > Wbs::TOLERANCE }
        raise Wbs::Error, "Bobot sub-tugas #{bad[:node].wbs_code} belum 100 %." if bad
      end
      draft = Baseline.draft_for(project)
      raise Wbs::Error, "Draft Baseline 0 tidak ditemukan." unless draft&.version&.zero?

      activate!(draft, actor)
    end

    # Rencana bulanan linear per aktivitas (lpms3.scurve_plan) untuk Kurva-S / StarRocks.
    def build_scurve!(baseline)
      ScurvePlan.where(baseline_id: baseline.id).delete_all
      rows = leaf_items(stored_items(baseline)).flat_map do |i|
        s = i[:date_plan_start]
        f = i[:date_plan_finish]
        days = (f - s).to_i + 1
        m = s.beginning_of_month
        out = []
        while m <= f
          from = [s, m].max
          to = [f, m.end_of_month].min
          out << { baseline_id: baseline.id, wbs_node_id: i[:wbs_node_id], period_start: m, granularity: "MONTH",
                   planned_weight: (i[:weight].to_d * ((to - from).to_i + 1) / days).round(9), method: "LINEAR" }
          m = m.next_month
        end
        out
      end
      ScurvePlan.insert_all!(rows) if rows.any?
    end

    # Aktivitas baseline (tanpa anak di baseline) yang bertanggal rencana.
    def leaf_items(items)
      parents = items.filter_map { |i| i[:parent_wbs_node_id] }.to_set
      items.select { |i| i[:parent_wbs_node_id] && !parents.include?(i[:wbs_node_id]) && i[:date_plan_start] && i[:date_plan_finish] }
    end

    def set_kickoff_date!(project, date)
      cf = ::ProjectCustomField.find_by(name: KICKOFF_FIELD)
      return unless cf && project.respond_to?(:custom_field_values)

      cv = ::CustomValue.find_or_initialize_by(customized_type: "Project", customized_id: project.id, custom_field_id: cf.id)
      return if cv.value.present?

      cv.value = date.iso8601
      cv.save!(validate: false)
    end

    # ---------- Kembalikan ke baseline aktif (setelah CR ditolak / perubahan dibatalkan) ----------

    def restore_active!(project, actor)
      active = Baseline.active_for(project)
      raise Wbs::Error, "Belum ada baseline aktif." unless active

      draft = Baseline.draft_for(project)
      raise Wbs::Error, "#{draft.label} sedang diproses lewat Change Request; tunggu keputusan CR." if draft && !cr_editable?(draft)

      kept = []
      Wbs.mutate!(project, actor) do
        items = stored_items(active).sort_by { |i| [i[:wbs_code] == "0" ? 0 : i[:wbs_code].count(".") + 1, i[:sort_order]] }
        parents = items.filter_map { |i| i[:parent_wbs_node_id] }.to_set
        live = WbsNode.where(project_id: project.id).index_by(&:id)
        frozen = WbsDoneSnapshot.where(project_id: project.id).pluck(:wbs_node_id).to_set
        map = {}
        items.each do |i|
          node = live[i[:wbs_node_id]]
          parent = i[:parent_wbs_node_id] && map[i[:parent_wbs_node_id]]
          next if i[:parent_wbs_node_id] && parent.nil?

          node ||= Wbs.create_node!(project, parent:, tasks: i[:tasks], sort: i[:sort_order], wf: i[:weigh_factor] || 0)
          attrs = { parent_id: parent&.id, sort_order: i[:sort_order], updated_by: actor.id, updated_at: Time.current }
          attrs[:weigh_factor] = i[:weigh_factor] if i[:weigh_factor] && !node.root?
          unless frozen.include?(node.id) || node.root?
            attrs[:tasks] = i[:tasks]
            attrs.merge!(date_plan_start: i[:date_plan_start], date_plan_finish: i[:date_plan_finish]) unless parents.include?(i[:wbs_node_id])
          end
          node.update_columns(attrs)
          map[i[:wbs_node_id]] = node
        end
        mapped = map.values.map(&:id).to_set
        extra = WbsNode.where(project_id: project.id).where.not(id: mapped.to_a).to_a
        extra.sort_by { |n| -Wbs.depth_of(n) }.each do |n|
          if n.children.reload.empty? && !n.pct.positive? && !Wbs.progress_history?(n)
            Wbs.destroy_node!(n)
          else
            kept << n.wbs_code
          end
        end
      end
      kept
    end

    # ---------- Ringkasan (Portfolio, Ikhtisar Fase, WBS) ----------

    # Rencana % pada tanggal: Σ weight aktivitas baseline aktif × fraksi waktu berjalan (linear).
    def planned_pct(baseline, date)
      return nil unless baseline

      items = leaf_items(stored_items(baseline))
      return nil if items.empty?

      total = items.sum do |i|
        s = i[:date_plan_start]
        f = i[:date_plan_finish]
        frac = if date < s then 0.0
               elsif date >= f then 1.0
               else ((date - s).to_i + 1).to_f / ((f - s).to_i + 1)
               end
        i[:weight].to_f * frac
      end
      (total * 100).round(2)
    end

    # Aktual % = % Progress Level 0 (Σ weight × % Complete).
    def actual_pct(project)
      root = WbsNode.find_by(project_id: project.id, parent_id: nil)
      root && WbsNode.where(parent_id: root.id).exists? ? (root.pct_progress.to_f * 100).round(2) : nil
    end

    # Aktual % pada tanggal lampau dari riwayat done_ratio WP aktivitas (jurnal LPMS).
    def actual_pct_at(project, date)
      rows = Wbs.rows(project).select { |r| r[:leaf] && !r[:node].root? && r[:node].work_package_id }
      return nil if rows.empty?

      total = rows.sum do |r|
        was = ::Lpms3::Portfolio.done_ratio_at(r[:node].work_package, date)
        r[:node].weight.to_f * (was.to_f / 100)
      end
      (total * 100).round(2)
    end

    def summary(project, today: Time.zone.today)
      return nil unless WbsNode.where(project_id: project.id).exists?

      active = Baseline.active_for(project)
      draft = Baseline.draft_for(project)
      { active:, draft:, planned: planned_pct(active, today), actual: actual_pct(project),
        frozen: WbsDoneSnapshot.where(project_id: project.id).count,
        rejected: Baseline.where(project_id: project.id, status: "REJECTED").order(version: :desc).first }
    end
  end
end
