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

# LPMS3 MOD-01: pengaman konfigurasi SSO terpusat ke IDS.
# Hanya MEMERIKSA dan mencatat log; tidak mengubah lisensi/EnterpriseToken maupun perilaku fitur.
Rails.application.config.after_initialize do
  begin
    problems = []
    %w[IDENTIFIER SECRET ISSUER AUTHORIZATION__ENDPOINT TOKEN__ENDPOINT USERINFO__ENDPOINT].each do |k|
      problems << "OPENPROJECT_OPENID__CONNECT_IDS_#{k} kosong" if ENV["OPENPROJECT_OPENID__CONNECT_IDS_#{k}"].to_s.strip.empty?
    end
    problems << "self_registration bukan 0 (nilai: #{Setting.self_registration})" unless Setting.self_registration.to_i.zero?
    problems << "login_required tidak aktif" unless Setting.login_required?

    if problems.empty?
      Rails.logger.info "[LPMS3] IDS SSO guard: variabel OIDC IDS lengkap (login pengguna berjalan lewat IdsLogin bridge; strategi OmniAuth OpenProject sendiri tidak dipakai)."
    else
      Rails.logger.warn "[LPMS3] IDS SSO guard: #{problems.join('; ')}"
    end
  rescue StandardError => e
    Rails.logger.warn "[LPMS3] IDS SSO guard dilewati: #{e.class}: #{e.message}"
  end
end
