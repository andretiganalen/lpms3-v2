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

# LPMS3 MOD-02: definisi pengaturan saklar fitur in-house. Default kosong (belum ada fitur selesai).
# Disimpan di tabel `settings`; tidak berkaitan dengan EnterpriseToken.
Rails.application.config.after_initialize do
  require "open_project/lpms3/features"
  if defined?(Settings::Definition) && !Settings::Definition.exists?(:internal_enabled_features)
    Settings::Definition.add :internal_enabled_features,
                             default: [],
                             format: :array,
                             writable: true
  end
end
