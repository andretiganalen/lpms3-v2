module Lpms3
  # Melayani CSS tema UIx dan font Poppins. Publik (dipakai juga di halaman login), hanya daftar putih berkas.
  class AssetsController < ::ApplicationController
    skip_before_action :check_if_login_required
    no_authorization_required! :show

    def show
      asset = OpenProject::Lpms3::Assets.files[params[:asset].to_s]
      return head(:not_found) unless asset

      expires_in 1.year, public: true
      send_file asset, type: OpenProject::Lpms3::Assets.type_for(asset), disposition: "inline"
    end
  end
end
