Rails.application.routes.draw do
  # Aset tema (CSS & font Poppins dilayani dari server sendiri; tanpa Google Fonts)
  get "lpms3/assets/:digest/*asset", to: "lpms3/assets#show", as: :lpms3_asset, format: false

  scope "admin" do
    get "lpms3/organisasi", to: "lpms3/admin/organisasi#index", as: :lpms3_admin_organisasi
    get "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#show", as: :lpms3_admin_internal_features
    patch "lpms3/internal_features", to: "lpms3/admin/internal_features_settings#update"
  end
end
