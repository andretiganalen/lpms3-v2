# frozen_string_literal: true

module Lpms3
  # Master rekanan (PFR-001), evaluasi penyedia (PFR-019), daftar hitam (PFR-030) — 1.43.
  # Kolom "Rekanan" Item Pengadaan tetap teks; dicocokkan ke master tanpa membedakan huruf besar/kecil.
  module Rekanan
    class Error < StandardError; end

    PENGADAAN_ROLES = ["Fungsi Pengadaan & Pengelola Gudang", "Pimpro", "Project admin"].freeze
    EVALUATOR_ROLES = ["Fungsi Pengadaan & Pengelola Gudang", "Pimpro", "Fungsi Penjaminan Mutu"].freeze
    HITAM_ROLES = ["Pejabat Eselon 1", "Pejabat Eselon 2"].freeze

    module_function

    def roles_in(user, project) = user.roles_for_project(project).map(&:name)
    def pengadaan?(user, project) = user.admin? || roles_in(user, project).intersect?(PENGADAAN_ROLES + ::Lpms3::Wbs::EDITOR_ROLES)

    # Global: admin atau pemegang peran pengadaan di salah satu proyek.
    def can_manage?(user)
      return false unless user&.logged?
      return true if user.admin?

      ::Member.joins(:roles).where(user_id: user.id, roles: { name: PENGADAAN_ROLES.first }).exists?
    end

    def can_blacklist?(user)
      return false unless user&.logged?

      user.admin? || ::Member.joins(:roles).where(user_id: user.id, roles: { name: HITAM_ROLES }).exists?
    end

    def can_evaluate?(user, project) = user.admin? || roles_in(user, project).intersect?(EVALUATOR_ROLES)

    def norm(name) = name.to_s.strip.downcase.gsub(/\s+/, " ")

    def find_by_name(name)
      return nil if name.blank?

      @cache ||= {}
      RekananRow.where("lower(nama) = ?", norm(name)).first
    end

    # Satu kali muat untuk banyak item: { nama_norm => row }.
    def index_by_name = RekananRow.all.index_by { |r| norm(r.nama) }

    def list(q: nil, status: nil)
      rel = RekananRow.order(:nama)
      rel = rel.where("nama ILIKE :q OR npwp ILIKE :q OR kategori ILIKE :q", q: "%#{q.strip}%") if q.present?
      rel = rel.where(status:) if %w[AKTIF DAFTAR_HITAM].include?(status)
      rows = rel.to_a
      evals = RekananEvaluasi.where(rekanan_id: rows.map(&:id)).group_by(&:rekanan_id)
      cf = ::WorkPackageCustomField.find_by(name: "Rekanan")
      pakai = cf ? ::CustomValue.where(customized_type: "WorkPackage", custom_field_id: cf.id).where.not(value: [nil, ""])
                               .pluck(:value).map { |v| norm(v) }.tally : {}
      rows.map do |r|
        ev = evals[r.id] || []
        { row: r, evaluasi: ev.size, skor: ev.any? ? (ev.sum(&:rata) / ev.size).round(2) : nil, item: pakai[norm(r.nama)] || 0 }
      end
    end

    def save!(user, attrs, id: nil)
      raise Error, "Hanya Fungsi Pengadaan atau admin yang mengelola rekanan." unless can_manage?(user)

      r = id ? RekananRow.find(id) : RekananRow.new(created_by: user.id)
      nama = attrs[:nama].to_s.strip.gsub(/\s+/, " ")
      raise Error, "Nama rekanan wajib diisi." if nama.empty?
      dup = RekananRow.where("lower(nama) = ?", norm(nama)).where.not(id: r.id).exists?
      raise Error, "Rekanan \"#{nama}\" sudah terdaftar." if dup

      r.assign_attributes(nama:, npwp: attrs[:npwp].to_s.strip.presence, alamat: attrs[:alamat].to_s.strip.presence,
                          kontak: attrs[:kontak].to_s.strip.presence, kategori: attrs[:kategori].to_s.strip.presence,
                          updated_by: user.id, updated_at: Time.current)
      r.save!
      r
    end

    def daftar_hitam!(user, id, alasan)
      raise Error, "Hanya admin atau Pejabat Eselon 1/2 yang menetapkan daftar hitam (PFR-030)." unless can_blacklist?(user)
      raise Error, "Alasan daftar hitam wajib diisi." if alasan.blank?

      RekananRow.find(id).tap do |r|
        r.update!(status: "DAFTAR_HITAM", alasan_hitam: alasan.to_s.strip, tanggal_hitam: Date.current, dihitamkan_by: user.id,
                  updated_by: user.id, updated_at: Time.current)
      end
    end

    def pulihkan!(user, id)
      raise Error, "Hanya admin atau Pejabat Eselon 1/2 yang mencabut daftar hitam." unless can_blacklist?(user)

      RekananRow.find(id).tap { |r| r.update!(status: "AKTIF", updated_by: user.id, updated_at: Time.current) }
    end

    def evaluasi!(user, wp, attrs)
      raise Error, "Anda tidak berwenang mengevaluasi penyedia proyek ini." unless can_evaluate?(user, wp.project)

      it = ::OpenProject::Lpms3::Procurement.items(::WorkPackage.where(id: wp.id)).first
      raise Error, "Bukan Item Pengadaan." unless it
      raise Error, "Evaluasi penyedia dilakukan mulai tahap GR/SES." if it.stage_index < ::OpenProject::Lpms3::Procurement::I_GR

      r = find_by_name(it.v[:vendor]) or raise(Error, "Rekanan \"#{it.v[:vendor]}\" belum terdaftar di master rekanan.")
      skor = %i[skor_mutu skor_waktu skor_harga skor_k3l].to_h do |k|
        v = attrs[k].to_i
        raise Error, "Skor harus 1–5." unless v.between?(1, 5)

        [k, v]
      end
      e = RekananEvaluasi.find_or_initialize_by(work_package_id: wp.id)
      e.assign_attributes(rekanan_id: r.id, project_id: wp.project_id, catatan: attrs[:catatan].to_s.strip.presence,
                          evaluator_id: user.id, tanggal: Date.current, **skor)
      e.save!
      e
    end
  end
end
