# frozen_string_literal: true

module Lpms3
  # Master rekanan (PFR-001) lintas proyek, evaluasi (PFR-019), daftar hitam (PFR-030) — 1.43.
  class RekananController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :index, :save, :hitam, :pulihkan
    current_menu_item { :lpms3_rekanan }
    layout "global"

    R = ::Lpms3::Rekanan

    def index
      @q = params[:q].to_s
      @status = params[:status].presence
      @rows = R.list(q: @q, status: @status)
      @manage = R.can_manage?(User.current)
      @hitam = R.can_blacklist?(User.current)
    end

    def save = act { r = R.save!(User.current, params.fetch(:r, {}).permit!.to_h.symbolize_keys, id: params[:id].presence); "Rekanan #{r.nama} disimpan." }
    def hitam = act { r = R.daftar_hitam!(User.current, params[:id], params[:alasan]); "#{r.nama} masuk daftar hitam." }
    def pulihkan = act { r = R.pulihkan!(User.current, params[:id]); "#{r.nama} dipulihkan." }

    private

    def act
      flash[:notice] = yield
    rescue R::Error, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      flash[:error] = e.is_a?(ActiveRecord::RecordNotFound) ? "Rekanan tidak ditemukan." : e.message
    ensure
      redirect_to lpms3_rekanan_path(q: params[:q].presence) unless performed?
    end
  end
end
