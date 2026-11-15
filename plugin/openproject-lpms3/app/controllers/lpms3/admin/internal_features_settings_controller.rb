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
  module Admin
    # Administration > Modul Fitur Internal: saklar On/Off fitur in-house LPMS3.
    # Saklar hanya berlaku untuk fitur berstatus IMPLEMENTED; tidak berkaitan dengan lisensi OpenProject.
    class InternalFeaturesSettingsController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      menu_item :lpms3_internal_features

      def show
        @clusters = ::InhouseFeatureCatalog.grouped_by_cluster
        @enabled = ::OpenProject::Lpms3::Features.enabled_keys.map(&:to_s)
        @available_count = ::OpenProject::Lpms3::Features::IMPLEMENTED.size
      end

      def update
        available = ::OpenProject::Lpms3::Features::IMPLEMENTED.map(&:to_s)
        selected =
          case params[:mode]
          when "all" then available
          when "none" then []
          else Array(params[:enabled_features]).map(&:to_s) & available
          end

        Setting.internal_enabled_features = selected
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: :show
      end
    end
  end
end
