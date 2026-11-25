# frozen_string_literal: true

module Lpms3
  # Galeri foto bukti proyek (laporan harian terkirim).
  class GalleryController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :show

    def show
      @project = ::Project.find_by(identifier: params[:project_id]) || ::Project.find_by(id: params[:project_id])
      return render_404 unless @project
      return deny_access unless User.current.allowed_in_project?(:view_work_packages, @project)

      @photos = ::Lpms3::Gallery.photos(@project, User.current)
    end
  end
end
