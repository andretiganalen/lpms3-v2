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


# LPMS3 MOD-04: widget Homescreen berkonten vendor (komunitas, upsell Enterprise, teaser fitur baru)
# dibuang dari daftar blok. Widget lain (welcome, favorit, meetings, my_account, news, administration) tetap.
Rails.application.config.after_initialize do
  removed = %w[community upsell new_features]
  blocks = OpenProject::Static::Homescreen[:blocks]
  blocks&.reject! { |block| removed.include?(block[:name].to_s) }
  Rails.logger.info "[LPMS3] Homescreen blocks: #{blocks&.filter_map { |b| b[:name] }&.join(', ')}"
end
