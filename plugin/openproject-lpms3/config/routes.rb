Rails.application.routes.draw do
  # Aset tema (CSS & font Poppins dilayani dari server sendiri; tanpa Google Fonts)
  get "lpms3/assets/:digest/*asset", to: "lpms3/assets#show", as: :lpms3_asset, format: false

  get "projects/:project_id/lpms3/fase/:phase(/:section)", to: "lpms3/phases#show", as: :lpms3_project_phase,
      constraints: { phase: /inisiasi|perencanaan|eksekusi|pengawasan|penutupan/, section: /ringkasan|gerbang|langkah|aspek|register/ }

  # Penetapan 9 Aspek PMP (Inisiasi): isi, lampiran, dan langkah reviu/persetujuan langsung di tabel.
  patch "projects/:project_id/lpms3/aspek/:id/isi", to: "lpms3/aspects#update", as: :lpms3_project_aspect_update
  post "projects/:project_id/lpms3/aspek/:id/lampiran", to: "lpms3/aspects#attach", as: :lpms3_project_aspect_attach
  post "projects/:project_id/lpms3/aspek/:id/langkah", to: "lpms3/aspects#step", as: :lpms3_project_aspect_step

  # LenO Mobile (mock-up): PIC dan Pejabat Eselon 2 di perangkat seluler.
  scope "lpms3/m", controller: "lpms3/mobile", as: "lpms3_m" do
    get "", action: :index, as: ""
    get "notifikasi", action: :notifikasi, as: :notifikasi
    get "persetujuan", action: :persetujuan, as: :persetujuan
    get "wo/:id", action: :aktivitas, as: :wo
    post "wo/:id/submit", action: :submit_wo, as: :submit
    get "wo/:id/laporan", action: :laporan, as: :laporan
    post "wo/:id/laporan", action: :simpan, as: :simpan
    get "wo/:id/kendala", action: :kendala, as: :kendala
    post "wo/:id/kendala", action: :buat_kendala, as: :buat_kendala
    get "persetujuan/:id", action: :keputusan, as: :keputusan
    get "persetujuan/:id/tolak", action: :tolak, as: :tolak
    post "persetujuan/:id/tolak", action: :tolak_simpan, as: :tolak_simpan
    post "persetujuan/:id/setujui", action: :setujui, as: :setujui
  end

  get "projects/:project_id/lpms3/pengadaan(/:sub)", to: "lpms3/procurement#show", as: :lpms3_project_procurement,
      constraints: { sub: /pr|buyer|penyelesaian/ }
  get "lpms3/pengadaan(/:sub)", to: "lpms3/procurement#show", as: :lpms3_procurement, constraints: { sub: /pr|buyer|penyelesaian/ }

  get "projects/:project_id/lpms3/galeri", to: "lpms3/gallery#show", as: :lpms3_project_galeri
  get "lpms3/portofolio", to: "lpms3/portfolio#show", as: :lpms3_portofolio
  get "lpms3/tugas", to: "lpms3/tasks#index", as: :lpms3_tugas
  post "lpms3/tugas/:id/langkah", to: "lpms3/tasks#langkah", as: :lpms3_tugas_langkah
  post "lpms3/kickoff/:id/tunjuk", to: "lpms3/tasks#kickoff_tunjuk", as: :lpms3_kickoff_tunjuk
  post "lpms3/kickoff/:id/undang", to: "lpms3/tasks#kickoff_undang", as: :lpms3_kickoff_undang
  post "lpms3/tugas/:id/tembusan", to: "lpms3/tasks#tembusan", as: :lpms3_tugas_tembusan
  post "lpms3/masukan/:wp_id", to: "lpms3/tasks#masukan", as: :lpms3_masukan
  post "lpms3/masukan/:id/selesai", to: "lpms3/tasks#selesai_masukan", as: :lpms3_masukan_selesai
  get "projects/:project_id/lpms3/pdf/aspek", to: "lpms3/pdf#aspek", as: :lpms3_project_pdf_aspek
  get "lpms3/pdf/laporan/:id", to: "lpms3/pdf#laporan", as: :lpms3_pdf_laporan
  post "projects/:project_id/lpms3/ajukan-semua", to: "lpms3/tasks#ajukan_semua", as: :lpms3_project_ajukan_semua
  post "projects/:project_id/lpms3/ajukan/:wp_id", to: "lpms3/tasks#ajukan", as: :lpms3_project_ajukan

  # Panel header gaya LenO (Reminder, Tasklist, Notifikasi): penyegaran berkala dan tandai notifikasi dibaca.
  get "lpms3/header/ringkasan", to: "lpms3/header#ringkasan", as: :lpms3_header_ringkasan, defaults: { format: :json }
  post "lpms3/header/notifikasi/baca", to: "lpms3/header#baca_notifikasi", as: :lpms3_header_baca, defaults: { format: :json }

  get "lpms3/panduan", to: "lpms3/guide#show", as: :lpms3_guide
  scope "lpms3/mata-uang", as: :lpms3_currencies do
    get "/", to: "lpms3/currencies#index", as: :index
    post "currencies", to: "lpms3/currencies#create_currency", as: :create_currency
    patch "currencies/:id", to: "lpms3/currencies#update_currency", as: :update_currency
    post "rates", to: "lpms3/currencies#create_rate", as: :create_rate
    post "fetch", to: "lpms3/currencies#fetch", as: :fetch
    patch "source", to: "lpms3/currencies#update_source", as: :update_source
    post "apply-budget", to: "lpms3/currencies#apply_budget", as: :apply_budget
  end
  post "lpms3/language", to: "lpms3/language#update", as: :lpms3_language

  # Pemicu proyek dari LenO (API mesin-ke-mesin, kunci X-Lpms3-Key; docs/plan/RANCANGAN-PEMICU-LENO.md §4).
  post "lpms3/api/pemicu-proyek", to: "lpms3/pemicu_leno#create", as: :lpms3_api_pemicu, format: false
  get "lpms3/api/pemicu-proyek/:kode_proyek", to: "lpms3/pemicu_leno#show", as: :lpms3_api_pemicu_status,
      constraints: { kode_proyek: %r{[^/]+} }, format: false

  # Registrasi dan persetujuan proyek dari pemicu LenO (1.37).
  get "lpms3/pemicu/:id", to: "lpms3/pemicu#show", as: :lpms3_pemicu
  post "lpms3/pemicu/:id/usulkan", to: "lpms3/pemicu#usulkan", as: :lpms3_pemicu_usulkan
  post "lpms3/pemicu/:id/putuskan", to: "lpms3/pemicu#putuskan", as: :lpms3_pemicu_putuskan
  post "lpms3/pemicu/:id/batalkan", to: "lpms3/pemicu#batalkan", as: :lpms3_pemicu_batalkan
  post "lpms3/pemicu/:id/buat-ulang", to: "lpms3/pemicu#buat_ulang", as: :lpms3_pemicu_buat_ulang

  scope "admin" do
    get "lpms3/pemicu-leno", to: "lpms3/admin/pemicu_leno#index", as: :lpms3_admin_pemicu_leno
    get "lpms3/organisasi", to: "lpms3/admin/organisasi#index", as: :lpms3_admin_organisasi
    get "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#show", as: :lpms3_admin_internal_features
    patch "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#update"
    get "lpms3/branding", to: "lpms3/admin/branding#show", as: :lpms3_admin_branding
    patch "lpms3/branding", to: "lpms3/admin/branding#update"
    post "lpms3/branding/reset", to: "lpms3/admin/branding#reset", as: :lpms3_admin_branding_reset
  end
end
