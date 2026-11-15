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
    # Administration > Tampilan: logo, favicon/thumbnail, dan warna aplikasi (in-house; bukan CustomStyle Enterprise).
    class BrandingController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      menu_item :lpms3_branding

      def show
        @b = ::OpenProject::Lpms3::Branding
      end

      def update
        b = ::OpenProject::Lpms3::Branding
        errors = []

        b::IMAGE_KEYS.each do |key|
          if params[:"remove_#{key}"] == "1"
            b.set(key, "")
          elsif (up = params[key]).respond_to?(:read)
            uri, err = b.data_uri_from(up)
            err ? errors << "#{t("lpms3.branding.#{key}")}: #{err}" : b.set(key, uri)
          end
        end

        b::COLOR_KEYS.each do |key|
          value = params[key].to_s.strip
          if params[:"default_#{key}"] == "1" || value.blank? then b.set(key, "")
          elsif b.valid_color?(value) then b.set(key, value.downcase == b::DEFAULTS[key] ? "" : value.downcase)
          else errors << "#{t("lpms3.branding.#{key}")}: harus berformat #RRGGBB"
          end
        end

        if errors.any? then flash[:error] = errors.join("; ")
        else flash[:notice] = t(:notice_successful_update)
        end
        redirect_to action: :show
      end

      def reset
        ::OpenProject::Lpms3::Branding::KEYS.each { |k| ::OpenProject::Lpms3::Branding.set(k, "") }
        flash[:notice] = t("lpms3.branding.reset_done")
        redirect_to action: :show
      end
    end
  end
end
