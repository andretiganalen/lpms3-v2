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

# LPMS3: pengaturan tampilan in-house (lihat OpenProject::Lpms3::Branding). Default kosong = tampilan bawaan.
Rails.application.config.after_initialize do
  require "open_project/lpms3/branding"
  OpenProject::Lpms3::Branding::KEYS.each do |key|
    name = :"lpms3_#{key}"
    next if Settings::Definition.exists?(name)

    Settings::Definition.add name, default: "", format: :string, writable: true
  end
end
