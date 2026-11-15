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

# LPMS3 audit: halaman daftar di luar rentang (mis. /projects?page=99, atau /admin/roles?page=2 setelah
# per_page=100) membuat komponen pagination melempar ArgumentError di dalam view -> HTTP 500 bawaan OpenProject.
# Untuk permintaan GET, arahkan ke halaman 1; error lain diteruskan ke penanganan 500 bawaan.
Rails.application.config.to_prepare do
  next if ApplicationController.instance_variable_get(:@lpms3_pagination_guard)

  ApplicationController.instance_variable_set(:@lpms3_pagination_guard, true)
  ApplicationController.rescue_from(ActionView::Template::Error) do |exception|
    cause = exception.cause
    if request.get? && cause.is_a?(ArgumentError) && cause.message.include?("current_page can't be larger than page_count")
      redirect_to "#{request.path}?#{request.query_parameters.merge('page' => 1).to_query}"
    else
      render_500 exception:
    end
  end
end
