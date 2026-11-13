Rails.application.routes.draw do
  # Aset tema (CSS & font Poppins dilayani dari server sendiri; tanpa Google Fonts)
  get "lpms3/assets/:digest/*asset", to: "lpms3/assets#show", as: :lpms3_asset, format: false

  scope "admin" do
    get "lpms3/organisasi", to: "lpms3/admin/organisasi#index", as: :lpms3_admin_organisasi
  end
end
