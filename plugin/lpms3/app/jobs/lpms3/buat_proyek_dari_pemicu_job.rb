# frozen_string_literal: true

module Lpms3
  # Membuat proyek dari template setelah registrasi pemicu LenO disetujui. Idempoten (ProjectTrigger#buat_proyek!).
  # Tidak diulang otomatis: galat tercatat di pemicu dan Admin Fungsi Pelaksanaan Proyek dapat meminta coba ulang.
  class BuatProyekDariPemicuJob < ::ApplicationJob
    def perform(trigger_id)
      trigger = ::Lpms3::ProjectTrigger.find_by(id: trigger_id)
      return unless trigger

      trigger.buat_proyek!
    rescue StandardError => e
      Rails.logger.error("[LPMS3] pemicu #{trigger_id}: pembuatan proyek gagal: #{e.class}: #{e.message}")
    end
  end
end
