Rails.application.routes.draw do
  # Aset tema (CSS & font Poppins dilayani dari server sendiri; tanpa Google Fonts)
  get "lpms3/assets/:digest/*asset", to: "lpms3/assets#show", as: :lpms3_asset, format: false

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
