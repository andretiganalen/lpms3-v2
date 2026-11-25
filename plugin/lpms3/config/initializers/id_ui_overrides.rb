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

# LPMS3 UIx aturan 3 (satu bahasa per tampilan): menerapkan terjemahan Indonesia dari config/lpms3_id_overrides.yml
# SESUDAH kamus inti dimuat (override lewat berkas locale plugin kalah dari kamus inti).
Rails.application.config.after_initialize do
  begin
    path = File.expand_path("../lpms3_id_overrides.yml", __dir__)
    data = YAML.safe_load_file(path) || {}
    I18n.t(:label_home, locale: :id) # memaksa kamus inti termuat lebih dulu
    nested = data.each_with_object({}) do |(key, value), tree|
      parts = key.split(".").map(&:to_sym)
      node = parts[0..-2].inject(tree) { |h, p| h[p] ||= {} }
      node[parts.last] = value
    end
    I18n.backend.store_translations(:id, nested)
    Rails.logger.info "[LPMS3] Terjemahan Indonesia: #{data.size} kunci diterapkan."
  rescue StandardError => e
    Rails.logger.warn "[LPMS3] Terjemahan Indonesia dilewati: #{e.class}: #{e.message}"
  end
end
