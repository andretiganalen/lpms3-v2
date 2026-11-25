# frozen_string_literal: true

module Lpms3
  # Registrasi dan persetujuan proyek dari pemicu LenO (1.37). Wewenang dari peran global, bukan admin.
  class PemicuController < ::ApplicationController
    before_action :require_login
    before_action :find_trigger
    no_authorization_required! :show, :usulkan, :putuskan, :batalkan, :buat_ulang
    layout "global" # sidebar global seperti LenO

    def show
      return deny_access unless @trigger.may_view?(User.current)

      @users = ::Lpms3::ProjectTrigger.user_options
      @templates = ::Project.templated.where(identifier: ::Lpms3::ProjectTrigger::TEMPLATES.keys).order(:name).to_a
      @kode_re = ::Lpms3::ProjectTrigger.kode_regexp
    end

    def usulkan
      act do
        @trigger.usulkan!(User.current, template: params[:template], nama_proyek: params[:nama_proyek],
                                        kode_proyek_lpms3: params[:kode_proyek_lpms3], pimpro_id: params[:pimpro_id],
                                        vp_id: params[:vp_id], catatan: params[:catatan])
        "Registrasi diajukan. Menunggu keputusan Pejabat Eselon 1 Fungsi Pelaksanaan Proyek."
      end
    end

    def putuskan
      act do
        @trigger.putuskan!(User.current, params[:keputusan], params[:catatan])
        @trigger.status == "disetujui" ? "Registrasi disetujui. Proyek sedang dibuat dari template." : "Registrasi dikembalikan ke Admin."
      end
    end

    def batalkan
      act do
        @trigger.batalkan!(User.current, params[:alasan])
        "Pemicu dibatalkan."
      end
    end

    def buat_ulang
      act do
        @trigger.coba_buat_ulang!(User.current)
        "Pembuatan proyek diminta ulang."
      end
    end

    private

    def find_trigger
      @trigger = ::Lpms3::ProjectTrigger.includes(events: :actor).find_by(id: params[:id])
      render_404 unless @trigger
    end

    def act
      begin
        flash[:notice] = yield
      rescue ::Lpms3::ProjectTrigger::Error => e
        flash[:error] = e.message
      rescue ActiveRecord::StaleObjectError
        flash[:error] = "Data sudah berubah. Muat ulang lalu coba lagi."
      end
      redirect_to lpms3_pemicu_path(@trigger)
    end
  end
end
