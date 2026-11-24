# frozen_string_literal: true

module Lpms3
  # Kode Proyek sebagai identitas proyek (1.48): identifier URL = Kode Proyek (format XXX-XXXXXXXX, 12 karakter) dan
  # prefiks nomor WBS. Selama Kode belum diisi, dipakai 12 karakter pertama judul proyek; Admin Eselon 1 Fungsi
  # Pelaksanaan Proyek diberi tugas untuk mengisinya (Inbox.kode_proyek).
  # Catatan: identifier OpenProject (mode klasik) hanya menerima huruf kecil, sehingga disimpan huruf kecil; tampilan
  # (prefiks WBS, daftar) memakai huruf kapital lewat .prefix.
  module KodeProyek
    CF_NAME = "Kode Proyek"
    LENGTH = 12
    SYSTEM_IDENTIFIERS = %w[info-umum].freeze

    module_function

    def field = ::ProjectCustomField.find_by(name: CF_NAME)

    def kode_of(project)
      cf = field or return nil
      ::CustomValue.where(custom_field_id: cf.id, customized_type: "Project", customized_id: project.id).pick(:value).to_s.strip.upcase.presence
    end

    # Prefiks tampilan: kode proyek (huruf kapital) atau 12 karakter pertama judul.
    def prefix(project)
      kode_of(project) || from_title(project.name)
    end

    def from_title(name)
      name.to_s.upcase.gsub(/[^A-Z0-9]+/, "-").gsub(/\A-+|-+\z/, "").first(LENGTH).delete_suffix("-").presence || "PROYEK"
    end

    def identifier_for(project)
      base = prefix(project).downcase.gsub(/[^a-z0-9\-_]/, "-")
      base = "p#{base}" if base.match?(/\A\d+\z/) # identifier tidak boleh murni angka
      taken = lambda do |c|
        ::Project.where.not(id: project.id).where("lower(identifier) = ?", c).exists? ||
          ::Project.identifier_slugs.for_identifier(c).excluding_project(project).exists?
      end
      candidate = base
      n = 1
      candidate = "#{base.first(LENGTH - n.to_s.size - 1).delete_suffix('-')}-#{n += 1}" while taken.(candidate)
      candidate
    end

    # Menyamakan identifier dengan Kode/judul. Identifier lama disimpan sebagai riwayat FriendlyId (URL lama tetap berlaku).
    def sync_identifier!(project)
      project = ::Project.find_by(id: project.id) or return
      return if SYSTEM_IDENTIFIERS.include?(project.identifier) || project.templated? # template dirujuk lewat identifier (pemicu, seed)

      new_id = identifier_for(project)
      return if new_id == project.identifier

      old = project.identifier
      project.update_columns(identifier: new_id)
      ::FriendlyId::Slug.find_or_create_by!(slug: old, sluggable_id: project.id, sluggable_type: "Project")
      ::Rails.logger.info("[LPMS3] identifier proyek #{old} -> #{new_id}")
      new_id
    rescue StandardError => e
      ::Rails.logger.warn("[LPMS3] sync identifier gagal (#{project&.id}): #{e.message}")
      nil
    end

    # Proyek aktif (bukan template/ruang informasi) yang Kode Proyeknya belum diisi.
    def tanpa_kode
      cf = field
      scope = ::Project.where(templated: false, active: true).where.not(identifier: SYSTEM_IDENTIFIERS)
      return scope.none unless cf

      has = ::CustomValue.where(custom_field_id: cf.id, customized_type: "Project").where.not(value: [nil, ""]).select(:customized_id)
      scope.where.not(id: has).order(:id)
    end

    # Tugas Admin Eselon 1 Fungsi Pelaksanaan Proyek (pemegang izin registrasi pemicu): isi Kode Proyek.
    def pending_for(user)
      return [] unless user&.logged? && ::Lpms3::ProjectTrigger.registrar?(user)

      tanpa_kode.to_a
    end
  end
end
