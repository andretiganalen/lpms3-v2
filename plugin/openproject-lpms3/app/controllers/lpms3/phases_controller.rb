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
      ph ? ::OpenProject::Lpms3::Phases.menu_name(ph) : :work_packages
    end

    layout "base"

    def show
      @phase = ::OpenProject::Lpms3::Phases.find(params[:phase])
      return render_404 unless @phase

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
