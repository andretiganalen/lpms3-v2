# frozen_string_literal: true

module Lpms3
  # Monitoring pengadaan & Kontrak Awal: pipeline PR → PO/Kontrak → GR/SES, temuan data, jatuh tempo kontrak.
  # Per project (hak: view_work_packages) atau lintas project (hanya project yang boleh dilihat pengguna).
  class ProcurementController < ::ApplicationController
    before_action :find_optional_project
    before_action :require_login_for_global
    no_authorization_required! :show, :tautkan, :evaluasi
    current_menu_item do |controller|
      sub = controller.params[:sub].presence
      next :lpms3_procurement unless controller.params[:project_id]

      sub ? :"lpms3_fase_eksekusi_pengadaan_#{sub}" : :lpms3_fase_eksekusi_pengadaan
    end
    layout -> { @project ? "base" : "global" } # sidebar project atau global

    def show
      scope = ::WorkPackage.visible(User.current)
      scope = scope.where(project_id: @project.id) if @project
      pr = ::OpenProject::Lpms3::Procurement
      @sub = pr::SUBS.key?(params[:sub].to_s) ? params[:sub].to_s : nil
      @items = pr.items(scope)
      @filter = params[:temuan].presence
      @stage = params[:tahap].presence
      @summary = pr.summary(@items)
      @budgets = pr.budget_rows(@items, project: @project)
      @shown = @sub ? @items.select { |it| pr::SUBS[@sub].cover?(it.stage_index) } : @items
      @shown = @shown.select { |it| it.findings.include?(@filter.to_sym) } if @filter && ::OpenProject::Lpms3::Procurement::SEVERITY.key?(@filter.to_sym)
      @shown = @shown.select { |it| it.stage == @stage } if @stage && ::OpenProject::Lpms3::Procurement::STAGES.include?(@stage)
      @base = ::OpenProject::Lpms3::Fx.base&.code || "IDR"
      if @project
        @wbs_acts = ::Lpms3::Wbs.rows(@project).select { |r| r[:leaf] && !r[:node].root? }.map { |r| r[:node] }
        @can_link = ::Lpms3::Rekanan.pengadaan?(User.current, @project)
        @can_eval = ::Lpms3::Rekanan.can_evaluate?(User.current, @project)
      end
    end

    # Tautkan Item Pengadaan ke aktivitas WBS (1.43); progres aktivitas mengikuti tahap pengadaan bila bukti ada.
    def tautkan
      rec = ::Lpms3::PengadaanWbs.link!(@project, User.current, params[:id], params[:wbs_node_id])
      flash[:notice] = rec ? "Item ditautkan ke #{rec.wbs_node.wbs_code} #{rec.wbs_node.tasks}." : "Tautan WBS dilepas."
    rescue ::Lpms3::Wbs::Error, ActiveRecord::RecordNotFound => e
      flash[:error] = e.is_a?(ActiveRecord::RecordNotFound) ? "Data tidak ditemukan." : e.message
    ensure
      redirect_to lpms3_project_procurement_path(@project, sub: params[:sub].presence, anchor: "daftar") unless performed?
    end

    def evaluasi
      wp = ::WorkPackage.find_by!(project_id: @project.id, id: params[:id])
      e = ::Lpms3::Rekanan.evaluasi!(User.current, wp, params.fetch(:e, {}).permit!.to_h.symbolize_keys)
      flash[:notice] = "Evaluasi penyedia disimpan (rata-rata #{e.rata})."
    rescue ::Lpms3::Rekanan::Error, ActiveRecord::RecordNotFound => e
      flash[:error] = e.is_a?(ActiveRecord::RecordNotFound) ? "Data tidak ditemukan." : e.message
    ensure
      redirect_to lpms3_project_procurement_path(@project, sub: params[:sub].presence, anchor: "daftar") unless performed?
    end

    private

    def find_optional_project
      return unless params[:project_id]

      @project = Project.find(params[:project_id])
      deny_access unless User.current.allowed_in_project?(:view_work_packages, @project)
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def require_login_for_global
      require_login unless @project || User.current.logged?
    end
  end
end
