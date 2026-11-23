# frozen_string_literal: true

module Lpms3
  # Pemicu proyek dari LenO (docs/plan/RANCANGAN-PEMICU-LENO.md). Satu baris per kode proyek.
  # Rilis 1.35 hanya menerima dan mencatat; pembaca LPMS-2 (1.36) dan registrasi/persetujuan (1.37) menyusul.
  class ProjectTrigger < ::ApplicationRecord
    self.table_name = "lpms3_project_triggers"

    STATUSES = %w[diterima data_siap data_gagal diusulkan dikembalikan disetujui proyek_dibuat selesai dibatalkan].freeze
    FINAL = %w[proyek_dibuat selesai dibatalkan].freeze
    # Klaim pembaca LPMS-2 yang lebih tua dari ini dianggap ditinggal; kiriman ulang LenO melepasnya.
    STALE_AFTER = 10.minutes
    KODE_RE = %r{\A[A-Z0-9][A-Z0-9._/-]{0,39}\z}

    belongs_to :project, optional: true
    has_many :events, -> { order(:created_at, :id) }, class_name: "Lpms3::ProjectTriggerEvent", inverse_of: :project_trigger

    validates :kode_proyek, presence: true, format: { with: KODE_RE }
    validates :status, inclusion: { in: STATUSES }
    validates :id_kiriman_terakhir, presence: true, length: { maximum: 100 }

    def self.normalize_kode(value) = value.to_s.strip.upcase

    # Mencatat satu kiriman LenO. Mengembalikan [pemicu, hasil]; hasil :baru | :ulang | :final | :konflik.
    # Idempoten: id_kiriman yang sama dengan kiriman terakhir tidak mengubah apa pun.
    def self.receive!(kode_proyek:, id_kiriman:, lpms2_proyek_id: nil, nota: {}, dikirim_pada: nil, alamat: nil)
      kode = normalize_kode(kode_proyek)
      attempts = 0
      begin
        transaction do
          now = Time.current
          trigger = lock.find_by(kode_proyek: kode)
          if trigger.nil?
            trigger = create!(kode_proyek: kode, lpms2_proyek_id:, status: "diterima", id_kiriman_terakhir: id_kiriman,
                              jumlah_kiriman: 1, diterima_pada: now, kiriman_terakhir_pada: now, nota: nota || {}, dikirim_pada:)
            trigger.log!("diterima", to: "diterima", note: "Pemicu pertama dari LenO#{" (#{alamat})" if alamat}.")
            next [trigger, :baru]
          end

          if lpms2_proyek_id && trigger.lpms2_proyek_id && lpms2_proyek_id != trigger.lpms2_proyek_id
            trigger.log!("konflik", note: "Kiriman ditolak: LPMS-2 proyek ID #{lpms2_proyek_id} berbeda dari yang tercatat " \
                                          "(#{trigger.lpms2_proyek_id}).")
            next [trigger, :konflik]
          end
          next [trigger, :final] if FINAL.include?(trigger.status)
          next [trigger, :ulang] if trigger.id_kiriman_terakhir == id_kiriman

          attrs = { id_kiriman_terakhir: id_kiriman, jumlah_kiriman: trigger.jumlah_kiriman + 1, kiriman_terakhir_pada: now }
          attrs[:lpms2_proyek_id] = lpms2_proyek_id if trigger.lpms2_proyek_id.nil? && lpms2_proyek_id
          attrs[:nota] = nota if nota.present?
          attrs[:dikirim_pada] = dikirim_pada if dikirim_pada
          note = "Kiriman ulang ke-#{attrs[:jumlah_kiriman]}."
          if trigger.status == "diterima" && trigger.diklaim_pada && trigger.diklaim_pada < STALE_AFTER.ago
            note += " Klaim pembaca sejak #{trigger.diklaim_pada.iso8601} dianggap ditinggal dan dilepas."
            attrs[:diklaim_pada] = nil
          end
          trigger.update!(attrs)
          trigger.log!("kiriman_ulang", from: trigger.status, to: trigger.status, note:)
          [trigger, :ulang]
        end
      rescue ActiveRecord::RecordNotUnique
        # Dua kiriman pertama datang bersamaan: yang kalah membaca ulang baris pemenang.
        retry if (attempts += 1) < 2
        raise
      end
    end

    def log!(kind, from: nil, to: nil, note: nil, actor: nil, sumber: actor ? "pengguna" : "leno")
      events.create!(kind:, from_status: from, to_status: to, note:, actor:, sumber:, created_at: Time.current)
    end

    def api_json
      { id:, kode_proyek:, status:, diterima_pada: diterima_pada&.iso8601, diperbarui_pada: updated_at&.iso8601,
        jumlah_kiriman:, proyek_url: project && "/projects/#{project.identifier}" }
    end
  end
end
