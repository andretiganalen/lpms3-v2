# frozen_string_literal: true

# LPMS3 (1.49): teks yang tampil ke pengguna tidak lagi menyebut "OpenProject" dan tidak merujuk situs OpenProject.
#  - Semua nilai terjemahan (kamus inti + plugin, semua bahasa termuat): "OpenProject" -> "LPMS";
#    alamat situs openproject.org/.com -> "/projects/info-umum/wiki" (panduan internal).
#  - Kunci, nama konstanta Ruby, nama gem, nama database, variabel lingkungan, dan berkas lisensi TIDAK diubah:
#    itu identitas kode inti (OpenProject::..., window.OpenProject) dan pemberitahuan hak cipta GPL wajib dipertahankan.
module Lpms3BrandText
  NAME = "LPMS"
  HELP = "/projects/info-umum/wiki"
  URL_RE = %r{https?://(?:[a-z0-9-]+\.)*openproject\.(?:org|com)[^\s"'<>)\]]*}i

  module_function

  def clean(value)
    case value
    when String
      return value unless value.include?("OpenProject") || value.match?(URL_RE)

      value.gsub(URL_RE, HELP).gsub("OpenProject", NAME)
    when Hash then value.each { |k, v| value[k] = clean(v) }
    when Array then value.map! { |v| clean(v) }
    else value
    end
  end

  def apply!
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    store = I18n.backend.send(:translations)
    store.each_value { |tree| clean(tree) }
  end
end

Rails.application.config.after_initialize do
  begin
    Lpms3BrandText.apply!
    Rails.logger.info "[LPMS3] Teks merek: OpenProject -> LPMS pada kamus terjemahan."
  rescue StandardError => e
    Rails.logger.warn "[LPMS3] Teks merek dilewati: #{e.class}: #{e.message}"
  end
end
