# frozen_string_literal: true

module Lpms3
  # Monitoring Kontrak awal (1.42): halaman per proyek (data kontrak, jaminan, termin, adendum) dan lintas proyek.
  class KontrakController < ::ApplicationController
    before_action :find_optional_project
    before_action :require_login_for_global
    no_authorization_required! :show, :index, :info, :jaminan, :jaminan_status, :termin, :tagih, :bayar, :adendum, :sahkan, :hapus
    current_menu_item { |c| c.params[:project_id] ? :lpms3_fase_inisiasi_kontrak : :lpms3_kontrak }
    layout -> { @project ? "base" : "global" }

    K = ::Lpms3::Kontrak

    def index
      @rows = K.rows(User.current)
      @filter = params[:temuan] == "1"
      @shown = @filter ? @rows.select { |s| s[:findings].any? } : @rows
    end

    def show
      @s = K.summary(@project)
      @edit = K.can_edit?(User.current, @project)
      @keu = K.keuangan?(User.current, @project)
      @pengesah = K.pengesah?(User.current, @project)
      @wbs_acts = ::Lpms3::Wbs.rows(@project).select { |r| r[:leaf] && !r[:node].root? }.map { |r| r[:node] }
      @crs = ::WorkPackage.joins(:type).where(project_id: @project.id, types: { name: "Change Request" }).order(:id).to_a
    end

    def info = act { K.save_info!(@project, User.current, form_params); "Data kontrak disimpan." }

    def jaminan
      act do
        j = K.save_jaminan!(@project, User.current, form_params, id: params[:id].presence)
        "#{j.label} #{j.nomor} disimpan."
      end
    end

    def jaminan_status
      act do
        j = K.set_jaminan_status!(@project, User.current, params[:id], params[:status])
        "#{j.label} #{j.nomor}: #{::Lpms3::KontrakJaminan::STATUS[j.status]}."
      end
    end

    def termin
      act do
        t = K.save_termin!(@project, User.current, form_params, id: params[:id].presence)
        "Termin #{t.urutan} disimpan."
      end
    end

    def tagih = act { t = K.tagih!(@project, User.current, params[:id], nomor: params[:nomor_tagihan], tanggal: params[:tanggal_tagih]); "Termin #{t.urutan} ditagih." }
    def bayar = act { t = K.bayar!(@project, User.current, params[:id], nilai: params[:nilai_bayar], tanggal: params[:tanggal_bayar]); "Termin #{t.urutan} dibayar." }

    def adendum
      act do
        a = K.save_adendum!(@project, User.current, form_params, id: params[:id].presence)
        "Adendum #{a.urutan} disimpan sebagai draft; menunggu pengesahan Pejabat Eselon 2/1."
      end
    end

    def sahkan
      act do
        a = K.sahkan_adendum!(@project, User.current, params[:id])
        msg = "Adendum #{a.urutan} disahkan; nilai/tanggal selesai kontrak diperbarui."
        if a.tanggal_selesai_baru && (root = ::Lpms3::WbsNode.find_by(project_id: @project.id, parent_id: nil)) &&
           root.date_plan_finish && root.date_plan_finish != a.tanggal_selesai_baru
          msg += " Sesuaikan WBS (selesai #{root.date_plan_finish}); perubahan WBS membuat draft baseline dan Change Request."
        end
        msg
      end
    end

    def hapus = act { K.destroy_draft!(@project, User.current, params[:jenis].to_s, params[:id]); "Data dihapus." }

    private

    def form_params = params.fetch(:k, {}).permit!.to_h.symbolize_keys

    def act
      flash[:notice] = yield
    rescue K::Error, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      flash[:error] = e.is_a?(ActiveRecord::RecordNotFound) ? "Data tidak ditemukan." : e.message
    ensure
      redirect_to lpms3_project_kontrak_path(@project, anchor: params[:anchor].presence) unless performed?
    end

    def find_optional_project
      return unless params[:project_id]

      @project = Project.find(params[:project_id])
      deny_access unless K.can_view?(User.current, @project)
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def require_login_for_global
      require_login unless @project || User.current.logged?
    end
  end
end
