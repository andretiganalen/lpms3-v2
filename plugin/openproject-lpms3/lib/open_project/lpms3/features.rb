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

# LPMS3 MOD-02: katalog fitur BUATAN SENDIRI (in-house). Ini BUKAN gerbang lisensi OpenProject:
# tidak menyentuh EnterpriseToken, tidak mengubah `allows_to?`, tidak mengaktifkan kode Enterprise.
# Saklar hanya mengatur fitur LPMS3 yang benar-benar sudah kita implementasikan (status :implemented).
module OpenProject::Lpms3
  module Features
    # [key, cluster] — urutan mengikuti Bagian 3 docs/plan/openproject_custom_plan.md
    CATALOG = [
      %i[sso_auth_providers A], %i[ldap_groups A], %i[scim_api A], %i[nextcloud_sso A], %i[placeholder_users A],
      %i[team_planner_view B], %i[board_view B], %i[gantt_pdf_export B], %i[baseline_comparison B],
      %i[portfolio_management B], %i[customize_life_cycle B],
      %i[custom_actions C], %i[custom_field_hierarchies C], %i[calculated_values C], %i[edit_attribute_groups C],
      %i[weighted_item_lists C], %i[work_package_subject_generation C], %i[work_package_query_relation_columns C],
      %i[work_package_sharing D], %i[project_list_sharing D], %i[one_drive_sharepoint_file_storage D],
      %i[mcp_server D], %i[project_creation_wizard D],
      %i[virus_scanning E], %i[capture_external_links E], %i[internal_comments E], %i[readonly_work_packages E],
      %i[date_alerts E], %i[meeting_templates E], %i[define_custom_style E],
      %i[conditional_highlighting F], %i[multiple_active_sprints F], %i[resource_management F],
      %i[time_entry_time_restrictions F], %i[xwiki_integration F]
    ].freeze

    KEYS = CATALOG.map(&:first).freeze

    # Fitur yang sudah selesai dikembangkan in-house. Kosong sampai modulnya dibuat.
    IMPLEMENTED = [].freeze

    module_function

    def keys = KEYS

    def cluster_of(key) = CATALOG.to_h[key.to_sym]

    def implemented?(key) = IMPLEMENTED.include?(key.to_sym)

    # Daftar fitur yang diaktifkan admin (Setting.internal_enabled_features), dibatasi ke katalog.
    def enabled_keys
      raw = Setting.internal_enabled_features
      Array(raw).map { |k| k.to_s.to_sym } & KEYS
    rescue StandardError
      []
    end

    # true hanya bila fitur in-house tsb sudah diimplementasikan DAN dinyalakan admin.
    def enabled?(key)
      implemented?(key) && enabled_keys.include?(key.to_sym)
    end
  end
end
