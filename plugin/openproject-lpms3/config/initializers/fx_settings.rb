# frozen_string_literal: true

# LPMS3: pengaturan sumber kurs (default kosong = tidak ada panggilan eksternal) dan jadwal ambil harian.
Rails.application.config.after_initialize do
  { lpms3_fx_source: "", lpms3_fx_auto: "" }.each do |name, default|
    next if Settings::Definition.exists?(name)

    Settings::Definition.add name, default:, format: :string, writable: true
  end
  Rails.application.config.good_job.cron.merge!(
    "Lpms3::FxFetchJob": { cron: "10 9 * * 1-5", class: "Lpms3::FxFetchJob" } # 09:10 hari kerja
  )
end
