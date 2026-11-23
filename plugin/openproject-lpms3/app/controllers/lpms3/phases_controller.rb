# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Lpms3
  # Halaman fase BOP-001 per project: stepper lima fase, gerbang, langkah, dan register terkait.
  class PhasesController < ::ApplicationController
    before_action :find_project_by_project_id
    before_action :require_view_work_packages
    no_authorization_required! :show
    # Sidebar menandai container fase yang sedang dibuka (lihat engine.rb).
    current_menu_item do |controller|
      ph = ::OpenProject::Lpms3::Phases.find(controller.params[:phase])
      next :work_packages unless ph

      # Anak menu (Ringkasan/Gerbang/Langkah/Register) yang aktif; induk fase ikut tersorot (li.open di sidebar).
      ::OpenProject::Lpms3::Phases.menu_name(ph, (controller.params[:section].presence || "ringkasan").to_sym)
    end

    layout "base"

    def show
      @phase = ::OpenProject::Lpms3::Phases.find(params[:phase])
      return render_404 unless @phase

      @section = (params[:section].presence || "ringkasan")
      @all = @section == "ringkasan"

      scope = ::WorkPackage.visible(User.current).where(project_id: @project.id)
      @phases = ::OpenProject::Lpms3::Phases::ALL
      @progress = @phases.to_h { |ph| [ph.key, progress_for(scope, ph)] }
      @steps = scope.where("work_packages.subject LIKE ?", "[#{@phase.prefix}-%")
                    .includes(:status, :assigned_to, :type).to_a
                    .sort_by { |wp| wp.subject[/-(\d+)\]/, 1].to_i }
      @gates = scope.joins(:type).where(types: { is_milestone: true })
                    .where(@phase.gates.map { "work_packages.subject LIKE ?" }.join(" OR "), *@phase.gates.map { "#{_1} %" })
                    .includes(:status).order(:id).to_a
      @type_rows = @phase.types.filter_map do |name|
        type = ::Type.find_by(name:)
        next unless type

        rel = scope.where(type_id: type.id)
        [type, rel.count, rel.joins(:status).where(statuses: { is_closed: true }).count]
      end

      return unless @section == "aspek"

      ap = ::OpenProject::Lpms3::Aspects
      @aspects = ap.scope(@project, User.current).includes(:status, :attachments).order(:id).to_a
      @can_edit = ap.editor?(User.current, @project)
      @can_attach = User.current.allowed_in_project?(:add_work_package_attachments, @project)
      @aspek_pending = ::Lpms3::ApprovalTask.pending.where(work_package_id: @aspects.map(&:id)).pluck(:work_package_id)
      @aspek_ready_ids = @can_edit ? @aspects.reject { |wp| @aspek_pending.include?(wp.id) || ::OpenProject::Lpms3::Aspects.locked?(wp) }.map(&:id) : []
      @is_approver = ap.approver?(User.current, @project)
      # Tombol Revisi hanya untuk yang berwenang memutus tugas yang sedang menunggu (tahap rantai, pemisahan tugas).
      @aspek_revisable = ::Lpms3::ApprovalTask.pending.where(work_package_id: @aspek_pending)
                                          .select { |t| t.actions_for(User.current).include?("revisi") }.map(&:work_package_id)
    end

    private

    def require_view_work_packages
      deny_access unless User.current.allowed_in_project?(:view_work_packages, @project)
    end

    def progress_for(scope, phase)
      rel = scope.where("work_packages.subject LIKE ?", "[#{phase.prefix}-%")
      total = rel.count
      done = rel.joins(:status).where(statuses: { is_closed: true }).count
      { total:, done: }
    end
  end
end
