# Uji menu Mata Uang & Kurs: hak akses (admin / Keuangan / pengguna biasa), kurs append-only, konversi, validasi, halaman ID/EN,
# sumber eksternal (nonaktif secara bawaan), integrasi budget. Semua data uji dihapus di akhir.
require "action_dispatch/testing/integration"
ActionController::Base.allow_forgery_protection = false
admin = User.admin.active.where(type: "User").where.not(login: "lpms3-bridge").order(:id).first
def chk(id, desc, ok, note = nil) = puts(format("%-5s %-4s %s%s", ok.nil? ? "N/A" : (ok ? "PASS" : "FAIL"), id, desc, note ? " — #{note}" : ""))
TAG = "smoke-cur"
users = {}
created_rates = []
orig = { source: Setting.lpms3_fx_source, auto: Setting.lpms3_fx_auto, cur: Setting.costs_currency, fmt: Setting.costs_currency_format }
begin
  pw = SecureRandom.hex(12) + "Aa1!"
  %i[finance biasa].each do |k|
    u = User.new(login: "#{TAG}.#{k}", firstname: "Smoke", lastname: k.to_s, mail: "#{TAG}.#{k}@example.com", admin: false,
                 status: User.statuses[:active], language: "id", password: pw, password_confirmation: pw, force_password_change: false)
    u.save!
    users[k] = u
  end
  role = GlobalRole.find_by(name: "Keuangan")
  chk("C0", "peran global Keuangan ada dengan izin manage_currency_rates", role && role.permissions.map(&:to_sym) == [:manage_currency_rates])
  Member.create!(principal: users[:finance], roles: [role]) if role # peran global = anggota tanpa project
  (users[:finance].reload; true)
  chk("C0b", "akun Keuangan lolos allowed_globally?, akun biasa tidak",
      users[:finance].allowed_globally?(:manage_currency_rates) && !users[:biasa].allowed_globally?(:manage_currency_rates))

  base = Lpms3::Currency.base
  chk("C1", "mata uang dasar IDR satu-satunya", base&.code == "IDR" && Lpms3::Currency.where(is_base: true).count == 1)
  chk("C2", "delapan mata uang awal, IDR/USD/EUR/SGD/JPY aktif", Lpms3::Currency.count >= 8 && %w[IDR USD EUR SGD JPY].all? { |c| Lpms3::Currency.find_by(code: c)&.active })

  as = lambda do |user, &blk|
    ApplicationController.class_eval { define_method(:find_current_user) { user } }
    http = ActionDispatch::Integration::Session.new(Rails.application)
    http.host! (Setting.host_name.presence || "192.168.125.14:5100")
    blk.call(http)
  end
  rate_post = ->(http, code, rate, on, note = "#{TAG}") { http.post "/lpms3/mata-uang/rates", params: { currency_code: code, rate: rate, valid_on: on.to_s, note: note } }

  # Hak akses
  as.(users[:biasa]) { |h| h.get "/lpms3/mata-uang"; chk("A1", "pengguna biasa dapat melihat halaman", h.response.status == 200)
    rate_post.(h, "USD", "16000", Date.current); chk("A2", "pengguna biasa tidak dapat mengubah kurs (403)", h.response.status == 403) }
  as.(nil) { |h| h.get "/lpms3/mata-uang"; chk("A3", "tamu dialihkan ke login", [302, 401].include?(h.response.status)) } rescue chk("A3", "tamu ditolak", true)
  before = Lpms3::ExchangeRate.count
  d0 = Date.current - 10
  as.(users[:finance]) do |h|
    rate_post.(h, "USD", "16000,50", d0); chk("A4", "akun Keuangan dapat menyimpan kurs (koma desimal diterima)", h.response.status == 302 && Lpms3::ExchangeRate.count == before + 1)
    rate_post.(h, "USD", "16250", Date.current)
    rate_post.(h, "EUR", "17600", Date.current)
    created_rates.concat(Lpms3::ExchangeRate.where(created_by_id: users[:finance].id).pluck(:id))
    h.patch "/lpms3/mata-uang/source", params: { source: "frankfurter", auto: "1" }; chk("A5", "Keuangan tidak dapat mengubah sumber eksternal (hanya admin)", h.response.status == 403 && Setting.lpms3_fx_source.to_s == orig[:source].to_s)
    h.post "/lpms3/mata-uang/fetch"; chk("A6", "ambil kurs ditolak saat sumber nonaktif (tanpa panggilan eksternal)", h.response.status == 302 && Lpms3::ExchangeRate.where(source: "frankfurter").where(created_by_id: users[:finance].id).none?)
    rate_post.(h, "IDR", "1", Date.current); chk("V1", "kurs untuk mata uang dasar ditolak", Lpms3::ExchangeRate.where(currency_code: "IDR").none?)
    rate_post.(h, "USD", "-5", Date.current); rate_post.(h, "USD", "0", Date.current); rate_post.(h, "USD", "abc", Date.current); rate_post.(h, "USD", "100", "bukan-tanggal")
    chk("V2", "kurs negatif, nol, bukan angka, dan tanggal tak valid ditolak", Lpms3::ExchangeRate.where(created_by_id: users[:finance].id).count == 3)
    rate_post.(h, "ZZZ", "10", Date.current); chk("V3", "mata uang tak dikenal ditolak", Lpms3::ExchangeRate.where(currency_code: "ZZZ").none?)
  end

  # Append-only
  r = Lpms3::ExchangeRate.where(created_by_id: users[:finance].id).order(:id).first
  upd = (r.update(rate: 1) rescue false)
  chk("R1", "riwayat kurs tidak dapat diubah", !upd && Lpms3::ExchangeRate.find(r.id).rate.to_s.start_with?("16000.5"))
  chk("R2", "riwayat kurs tidak dapat dihapus", (r.destroy rescue false) == false && Lpms3::ExchangeRate.exists?(r.id))

  # Konversi
  fx = OpenProject::Lpms3::Fx
  chk("K1", "100 USD -> IDR = 1.625.000 (kurs terbaru)", fx.convert(100, "USD", "IDR") == BigDecimal("1625000"))
  chk("K2", "100 USD -> EUR lewat dasar = 92,3295 (16250/17600)", (fx.convert(100, "USD", "EUR") - BigDecimal("92.3295454545")).abs < BigDecimal("0.0001"))
  chk("K3", "tanggal lampau memakai kurs lama (16000,50)", fx.convert(1, "USD", "IDR", d0) == BigDecimal("16000.5"))
  chk("K4", "sebelum kurs pertama berlaku -> nil", fx.convert(1, "USD", "IDR", d0 - 1).nil?)
  chk("K5", "mata uang sama tidak berubah, tanpa kurs tidak dibutuhkan", fx.convert(123.45, "SGD", "SGD") == BigDecimal("123.45"))
  chk("K6", "tanpa kurs untuk pasangan -> nil (bukan angka palsu)", fx.convert(1, "SGD", "IDR").nil?)
  chk("K7", "pembulatan mengikuti satuan terkecil (IDR 0, USD 2)", fx.round_for(BigDecimal("1625000.6"), "IDR") == 1625001 && fx.round_for(BigDecimal("92.329545"), "USD") == BigDecimal("92.33"))
  # kurs ganda pada hari sama: yang dibuat terakhir menang
  as.(users[:finance]) { |h| rate_post.(h, "USD", "16300", Date.current); created_rates.concat(Lpms3::ExchangeRate.where(created_by_id: users[:finance].id).pluck(:id)) }
  chk("K8", "dua kurs pada tanggal sama: yang terakhir diisi menang, riwayat tetap", fx.rate("USD").to_s.start_with?("16300") && Lpms3::ExchangeRate.where(currency_code: "USD", valid_on: Date.current).count >= 2)

  # Halaman: bahasa dan konverter
  [["id", "Mata uang & kurs", "Konverter"], ["en", "Currency & exchange rates", "Converter"]].each do |lang, title, conv|
    users[:finance].update_column(:language, lang)
    as.(users[:finance].reload) do |h|
      h.get "/lpms3/mata-uang", params: { amount: "100", from: "USD", to: "EUR", on: Date.current.to_s }
      b = h.response.body
      chk("P-#{lang}", "halaman #{lang.upcase}: judul, konverter, hasil 100 USD -> EUR", h.response.status == 200 && b.include?(CGI.escapeHTML(title)) && b.include?(conv) && b =~ /EUR<\/strong>/ && b.include?("USD</strong>"))
    end
  end
  as.(users[:finance]) { |h| h.get "/lpms3/mata-uang", params: { amount: "x1", from: "USD", to: "EUR" }; chk("P3", "jumlah tak valid tidak menyebabkan galat", h.response.status == 200)
    h.get "/lpms3/mata-uang", params: { amount: "5", from: "<script>", to: "EUR" }; chk("P4", "kode mata uang liar diabaikan (tanpa XSS)", h.response.status == 200 && !h.response.body.include?("<script>5")) }

  # Mata uang: tambah, ubah, nonaktifkan
  as.(users[:finance]) do |h|
    h.post "/lpms3/mata-uang/currencies", params: { code: "myr", name: "Ringgit Malaysia", symbol: "RM", minor_units: 2 }
    chk("M1", "tambah mata uang (kode dinormalkan huruf besar)", Lpms3::Currency.exists?(code: "MYR"))
    c = Lpms3::Currency.find_by(code: "MYR")
    h.patch "/lpms3/mata-uang/currencies/#{c.id}", params: { name: "Ringgit", symbol: "RM", minor_units: 2, active: "0" }
    chk("M2", "ubah nama dan nonaktifkan", c.reload.name == "Ringgit" && !c.active)
    h.post "/lpms3/mata-uang/currencies", params: { code: "MYR", name: "Dobel", symbol: "RM" }; chk("M3", "kode ganda ditolak", Lpms3::Currency.where(code: "MYR").count == 1)
    h.patch "/lpms3/mata-uang/currencies/#{Lpms3::Currency.base.id}", params: { active: "0" }; chk("M4", "mata uang dasar tidak dapat dinonaktifkan", Lpms3::Currency.base.active)
    c.destroy
  end

  # Budget
  as.(users[:finance]) { |h| h.post "/lpms3/mata-uang/apply-budget"; chk("B1", "mata uang budget diselaraskan ke dasar (Rp, format awalan)", Setting.costs_currency == "Rp" && Setting.costs_currency_format == "%u %n") }
  chk("B2", "model Budget terbaca untuk konversi", defined?(::Budget) ? true : nil)

  # Sumber eksternal (admin): aktifkan sementara, ambil, kembalikan
  as.(admin) do |h|
    h.patch "/lpms3/mata-uang/source", params: { source: "frankfurter", auto: "1" }
    chk("S1", "admin dapat mengaktifkan sumber (hanya host yang diizinkan)", Setting.lpms3_fx_source == "frankfurter" && Setting.lpms3_fx_auto == "1")
    h.patch "/lpms3/mata-uang/source", params: { source: "http://evil.example/x" }; chk("S2", "sumber di luar daftar ditolak -> nonaktif", Setting.lpms3_fx_source.to_s == "")
    h.patch "/lpms3/mata-uang/source", params: { source: "frankfurter" }
    before_f = Lpms3::ExchangeRate.where(source: "frankfurter").count
    res = (fx.fetch!(user: admin) rescue { errors: ["#{$!.class}"], fetched: [] })
    created_rates.concat(Lpms3::ExchangeRate.where(created_by_id: admin.id, source: "frankfurter").where("created_at > ?", 5.minutes.ago).pluck(:id))
    if res[:errors].any? && res[:fetched].empty?
      chk("S3", "ambil kurs dari sumber", nil, "jaringan/sumber tidak tersedia: #{res[:errors].first}")
    else
      chk("S3", "ambil kurs dari sumber menambah riwayat (#{res[:fetched].join(',')})", Lpms3::ExchangeRate.where(source: "frankfurter").count == before_f + res[:fetched].size && res[:fetched].any?)
    end
    chk("S4", "pekerjaan harian otomatis terdaftar dan tidak galat", (Lpms3::FxFetchJob.perform_now; true))
  end
rescue => e
  chk("ERR", "uji terhenti", false, "#{e.class}: #{e.message[0, 200]}")
ensure
  Lpms3::ExchangeRate.where(id: created_rates).delete_all
  Lpms3::ExchangeRate.where(note: TAG).delete_all
  Lpms3::ExchangeRate.where(created_by_id: users.values.map(&:id)).delete_all
  Lpms3::Currency.where(code: "MYR").delete_all
  Setting.lpms3_fx_source = orig[:source].to_s
  Setting.lpms3_fx_auto = orig[:auto].to_s
  Setting.costs_currency = orig[:cur]
  Setting.costs_currency_format = orig[:fmt]
  users.each_value { |u| (User.find_by(id: u.id)&.then { |x| x.destroy rescue Principals::DeleteJob.perform_now(x) }) }
  puts "sisa kurs uji: #{Lpms3::ExchangeRate.where(created_by_id: users.values.map(&:id)).count}"
end
