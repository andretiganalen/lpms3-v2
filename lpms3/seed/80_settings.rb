require_relative "00_data"
# Pengaturan aplikasi sesuai UIx (docs/skills/uIx-len-web-apps.md §7–8). Idempoten.
# - Nama produk "LPMS3" (judul tab, placeholder pencarian, email).
# - Bahasa default Indonesia; pilihan bahasa hanya Bahasa Indonesia dan English.
# - Akun manusia yang tersimpan "en" karena dibuat saat default masih "en" dipindah ke "id".
#   Akun layanan (lpms3-bridge) tidak diubah.
Setting.app_title = "LPMS3"
Setting.default_language = "id"
Setting.available_languages = %w[id en]

moved = User.human.where(language: [nil, "", "en"]).where.not(login: "lpms3-bridge")
n = moved.count
moved.update_all(language: "id")

puts "settings ok: app_title=#{Setting.app_title}, default_language=#{Setting.default_language}, " \
     "available_languages=#{Setting.available_languages.join(',')}, user dipindah ke id: #{n}"
