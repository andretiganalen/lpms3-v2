# frozen_string_literal: true

require "net/http"
require "json"
require "bigdecimal"

module OpenProject::Lpms3
  # Mata uang dan konversi korporasi. Semua angka BigDecimal. Kurs disimpan sebagai nilai 1 unit mata uang dalam mata uang dasar.
  module Fx
    # Satu-satunya sumber eksternal yang diizinkan: harus di-opt-in (setting lpms3_fx_source) dan host-nya tetap (bukan input pengguna).
    SOURCES = {
      "frankfurter" => { host: "api.frankfurter.dev", label: "ECB via Frankfurter (api.frankfurter.dev)" }
    }.freeze
    HTTP_TIMEOUT = 8
    MAX_BYTES = 64 * 1024

    module_function

    def source = Setting.respond_to?(:lpms3_fx_source) ? Setting.lpms3_fx_source.to_s : ""
    def source_enabled? = SOURCES.key?(source)
    def auto? = Setting.lpms3_fx_auto.to_s == "1"

    def base = ::Lpms3::Currency.base

    # Mata uang dasar -> 1. Selain itu kurs efektif pada tanggal (nil bila belum ada).
    def rate(code, on = Date.current)
      return BigDecimal(1) if code == base&.code

      ::Lpms3::ExchangeRate.effective(code, on)&.rate
    end

    # Konversi lewat mata uang dasar: jumlah * kurs(dari) / kurs(ke). Mengembalikan nil bila kurs belum ada.
    def convert(amount, from, to, on = Date.current)
      a = BigDecimal(amount.to_s)
      return a if from == to

      rf = rate(from, on)
      rt = rate(to, on)
      return nil unless rf && rt

      a * rf / rt
    end

    # Bulatkan sesuai satuan terkecil mata uang tujuan.
    def round_for(value, code)
      cur = ::Lpms3::Currency.find_by(code:)
      value&.round(cur&.minor_units || 2)
    end

    # Ambil kurs dari sumber yang dipilih untuk semua mata uang aktif non-dasar. Setiap hasil menjadi baris riwayat baru.
    def fetch!(user: nil)
      raise "Sumber kurs belum diaktifkan" unless source_enabled?

      host = SOURCES.fetch(source)[:host]
      b = base or raise "Mata uang dasar belum ditetapkan"
      fetched = []
      skipped = []
      errors = []
      ::Lpms3::Currency.active.where(is_base: false).ordered.each do |cur|
        data = get_json(host, "/v1/latest", base: cur.code, symbols: b.code)
        r = data.dig("rates", b.code)
        date = Date.iso8601(data["date"].to_s)
        if r.nil?
          skipped << cur.code
          next
        end
        ::Lpms3::ExchangeRate.create!(currency_code: cur.code, rate: BigDecimal(r.to_s), valid_on: date, source: source, created_by: user,
                                      note: "Otomatis dari #{host}")
        fetched << cur.code
      rescue StandardError => e
        errors << "#{cur.code}: #{e.class}: #{e.message[0, 100]}"
      end
      { fetched:, skipped:, errors: }
    end

    def get_json(host, path, params)
      uri = URI::HTTPS.build(host:, path:, query: URI.encode_www_form(params))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = HTTP_TIMEOUT
      http.read_timeout = HTTP_TIMEOUT
      res = http.request(Net::HTTP::Get.new(uri))
      raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      raise "respons terlalu besar" if res.body.to_s.bytesize > MAX_BYTES

      JSON.parse(res.body)
    end

    # Selaraskan pengaturan biaya/budget OpenProject dengan mata uang dasar korporasi.
    def apply_base_to_budget_settings!
      b = base or return
      Setting.costs_currency = b.symbol
      Setting.costs_currency_format = "%u %n"
    end
  end
end
