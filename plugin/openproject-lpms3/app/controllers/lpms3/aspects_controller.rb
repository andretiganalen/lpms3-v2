# frozen_string_literal: true

module Lpms3
  # Penetapan 9 Aspek PMP (BOP-001 §5.1): isi, lampiran, dan langkah reviu/persetujuan langsung di tabel.
  # Perubahan lewat service WorkPackages (izin dan workflow OpenProject tetap berlaku).
  class AspectsController < ::ApplicationController
    AP = ::OpenProject::Lpms3::Aspects

    before_action :find_project_by_project_id
    before_action :find_aspect
    no_authorization_required! :update, :attach, :step

    def update
      return deny_access unless AP.content_editable?(@aspect, User.current, @project)

      @aspect.journal_notes = "Perbaikan kecil dari masukan (tanpa reviu ulang)" if AP.locked?(@aspect)
      call = ::WorkPackages::UpdateService.new(user: User.current, model: @aspect)
                                          .call(description: params[:description].to_s)
      respond(call, :saved)
    end

    def attach
      return deny_access unless AP.editor?(User.current, @project) && !AP.locked?(@aspect)
      return deny_access unless User.current.allowed_in_project?(:add_work_package_attachments, @project)

      file = params[:file]
      unless file.respond_to?(:original_filename)
        flash[:error] = t("lpms3.pmp9.flash.no_file")
        return redirect_to_aspects
      end

      call = ::Attachments::CreateService.new(user: User.current)
                                         .call(container: @aspect, file:, filename: file.original_filename)
      respond(call, :attached)
    end

    def step
      name = params[:step].to_s
      return render_404 unless AP::STEPS.key?(name)
      return deny_access unless AP.can_step?(name, @aspect, User.current, @project)

      note = params[:note].to_s.strip
      if name == "revision" && note.empty?
        flash[:error] = t("lpms3.pmp9.flash.note_required")
        return redirect_to_aspects
      end

      # Reviu dan Revisi hanya lewat rantai persetujuan (Lpms3::ApprovalTask): "submit" membuat tugas di Tugas,
      # "revision" memutus tugas yang sedang menunggu. Dengan begitu status Reviu selalu punya tugas dan pemutus,
      # dan tugas tidak pernah tertinggal "menunggu" sesudah dokumen dikembalikan.
      if name == "submit"
        ::Lpms3::ApprovalTask.ajukan!(@aspect, User.current, note: note)
      else
        task = ::Lpms3::ApprovalTask.pending.find_by(work_package_id: @aspect.id)
        return deny_access unless task&.actions_for(User.current)&.include?("revisi")

        task.act!(User.current, "revisi", note)
      end
      flash[:notice] = t("lpms3.pmp9.flash.#{name}")
      redirect_to_aspects
    rescue ::Lpms3::ApprovalTask::Error => e
      flash[:error] = e.message
      redirect_to_aspects
    end

    private

    def find_aspect
      @aspect = AP.scope(@project, User.current).find_by(id: params[:id])
      render_404 unless @aspect
    end

    def respond(call, key)
      if call.success?
        flash[:notice] = t("lpms3.pmp9.flash.#{key}")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to_aspects
    end

    def redirect_to_aspects
      redirect_to lpms3_project_phase_path(@project, "inisiasi", "aspek")
    end
  end
end
