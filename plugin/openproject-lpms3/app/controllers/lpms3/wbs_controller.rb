# frozen_string_literal: true

module Lpms3
  # Editor WBS (1.40): tabel bobot cascading per proyek. Sel disimpan satu per satu lewat fetch (JSON); server
  # mengembalikan isi <tbody> + peringatan yang dirender ulang, sehingga nomor WBS, bobot, dan progres selalu dari server.
  class WbsController < ::ApplicationController
    before_action :find_project_by_project_id, except: :tugaskan
    before_action :authorize_view, except: :tugaskan
    before_action :authorize_edit, only: %i[update create destroy move weights bell_curve baseline0 restore]
    no_authorization_required! :show, :update, :create, :destroy, :move, :weights, :bell_curve, :tugaskan, :baseline0, :restore
    menu_item :lpms3_fase_perencanaan_wbs

    def show
      ::Lpms3::Wbs.ensure_root!(@project) if ::Lpms3::Wbs.can_edit?(User.current, @project)
      load_table
    end

    def update
      ::Lpms3::Wbs.update_field!(@project, User.current, params[:id], params[:field], params[:value])
      respond_table
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    def create
      node = ::Lpms3::Wbs.add_child!(@project, User.current, parent_id: params.require(:parent_id), after_id: params[:after_id].presence)
      respond_table(focus: node.id)
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    def destroy
      ::Lpms3::Wbs.delete!(@project, User.current, params[:id])
      respond_table
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    def move
      ::Lpms3::Wbs.move!(@project, User.current, params[:id], params[:dir])
      respond_table(focus: params[:id].to_i)
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    def weights
      ::Lpms3::Wbs.set_weights!(@project, User.current, params[:id], params.fetch(:bobot, {}).to_unsafe_h)
      respond_table
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    def bell_curve
      ::Lpms3::Wbs.bell_curve!(@project, User.current, params[:id])
      respond_table
    rescue ::Lpms3::Wbs::Error => e
      respond_error(e)
    end

    # Pimpro/Project Analis menetapkan Baseline 0 (Kick-Off) dari draft.
    def baseline0
      b = ::Lpms3::WbsBaseline.tetapkan_baseline0!(@project, User.current)
      flash[:notice] = "#{b.label} ditetapkan. Perubahan rencana berikutnya otomatis menjadi draft baseline dengan Change Request (BFR-001)."
      redirect_to lpms3_project_wbs_path(@project)
    rescue ::Lpms3::Wbs::Error => e
      flash[:error] = e.message
      redirect_to lpms3_project_wbs_path(@project)
    end

    # Kembalikan rencana WBS ke baseline aktif (mis. setelah CR ditolak).
    def restore
      kept = ::Lpms3::WbsBaseline.restore_active!(@project, User.current)
      flash[:notice] = "WBS dikembalikan ke baseline aktif." +
                       (kept.any? ? " Baris berprogres dipertahankan: #{kept.join(', ')}." : "")
      redirect_to lpms3_project_wbs_path(@project)
    rescue ::Lpms3::Wbs::Error => e
      flash[:error] = e.message
      redirect_to lpms3_project_wbs_path(@project)
    end

    # Kepala/Admin Eselon 1 menugaskan anggota timnya sebagai PIC (dari Tugas & Notifikasi).
    def tugaskan
      node = ::Lpms3::Wbs.assign_from_unit!(User.current, params[:id], params[:user_id])
      flash[:notice] = "#{node.pic_user.name} ditugaskan sebagai PIC #{node.wbs_code} #{node.tasks} (#{node.project.name})."
      redirect_to lpms3_tugas_path
    rescue ::Lpms3::Wbs::Error, ActiveRecord::RecordNotFound => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end

    private

    def authorize_view
      deny_access unless ::Lpms3::Wbs.can_view?(User.current, @project)
    end

    def authorize_edit
      return if ::Lpms3::Wbs.can_edit?(User.current, @project)

      request.format.json? ? render(json: { error: "Hanya Pimpro/Project Analis yang dapat mengubah WBS." }, status: :forbidden) : deny_access
    end

    def load_table
      @rows = ::Lpms3::Wbs.rows(@project)
      @kode_prefix = ::Lpms3::KodeProyek.prefix(@project)
      @editable = ::Lpms3::Wbs.can_edit?(User.current, @project)
      @members = ::Lpms3::Wbs.member_options(@project)
      @units = ::Lpms3::Wbs.eselon1_units
      @warnings = ::Lpms3::Wbs.warnings(@rows)
      @frozen = ::Lpms3::Wbs.frozen_ids(@rows.map { |r| r[:node] })
      @baseline = ::Lpms3::WbsBaseline.summary(@project)
      @cr_type = ::Lpms3::WbsBaseline.cr_type(@project)
      @pengadaan = ::Lpms3::PengadaanWbs.summary(@project)
    end

    def respond_table(focus: nil)
      load_table
      render json: { tbody: render_to_string(partial: "lpms3/wbs/rows", formats: [:html]),
                     warnings: render_to_string(partial: "lpms3/wbs/warnings", formats: [:html]),
                     baseline: render_to_string(partial: "lpms3/wbs/baseline", formats: [:html]), focus: }
    end

    def respond_error(error)
      load_table
      render json: { error: error.message, tbody: render_to_string(partial: "lpms3/wbs/rows", formats: [:html]),
                     warnings: render_to_string(partial: "lpms3/wbs/warnings", formats: [:html]),
                     baseline: render_to_string(partial: "lpms3/wbs/baseline", formats: [:html]) },
             status: :unprocessable_entity
    end
  end
end
