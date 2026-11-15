Rails.application.routes.draw do
  # Aset tema (CSS & font Poppins dilayani dari server sendiri; tanpa Google Fonts)
  get "lpms3/assets/:digest/*asset", to: "lpms3/assets#show", as: :lpms3_asset, format: false

  get "projects/:project_id/lpms3/fase/:phase(/:section)", to: "lpms3/phases#show", as: :lpms3_project_phase,
      constraints: { phase: /inisiasi|perencanaan|eksekusi|pengawasan|penutupan/, section: /ringkasan|gerbang|langkah|register/ }

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

  scope "admin" do
    get "lpms3/organisasi", to: "lpms3/admin/organisasi#index", as: :lpms3_admin_organisasi
    get "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#show", as: :lpms3_admin_internal_features
    patch "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#update"
    get "lpms3/branding", to: "lpms3/admin/branding#show", as: :lpms3_admin_branding
    patch "lpms3/branding", to: "lpms3/admin/branding#update"
    post "lpms3/branding/reset", to: "lpms3/admin/branding#reset", as: :lpms3_admin_branding_reset
  end
end
