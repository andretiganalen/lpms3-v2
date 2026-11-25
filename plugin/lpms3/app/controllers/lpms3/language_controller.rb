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
  # Pemilih bahasa di pojok kanan atas: mengubah bahasa akun yang sedang login (hanya yang tersedia di Setting).
  class LanguageController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :update

    def update
      lang = params[:lang].to_s
      if Setting.available_languages.map(&:to_s).include?(lang)
        User.current.update_column(:language, lang)
      end
      back = params[:back].to_s
      redirect_to(back.start_with?("/") && !back.start_with?("//") ? back : "/")
    end
  end
end
