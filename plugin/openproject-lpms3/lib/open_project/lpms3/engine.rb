require "open_project/plugins"
require "open_project/lpms3/features"
require "open_project/lpms3/branding"
require "open_project/lpms3/phases"

module OpenProject::Lpms3
  class Engine < ::Rails::Engine
    engine_name :openproject_lpms3

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-lpms3",
             author_url: "https://github.com/andretiganalen/lpms3-v2" do
      menu :admin_menu,
           :lpms3_organisasi,
           { controller: "/lpms3/admin/organisasi", action: :index },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.organisasi.menu",
           icon: "organization"

      menu :admin_menu,
           :lpms3_internal_features,
           { controller: "/lpms3/admin/internal_features_settings", action: :show },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.internal_features.menu",
           icon: "gear"

      menu :admin_menu,
           :lpms3_branding,
           { controller: "/lpms3/admin/branding", action: :show },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.branding.menu",
           icon: "gear"

      # Menu project per fase BOP-001: lima container (drilldown) berurutan tepat di bawah Ikhtisar.
      visible = ->(project) { project.module_enabled?("work_package_tracking") && User.current.allowed_in_project?(:view_work_packages, project) }
      previous = :overview
      OpenProject::Lpms3::Phases::ALL.each do |ph|
        parent = OpenProject::Lpms3::Phases.menu_name(ph)
        url = { controller: "/lpms3/phases", action: :show, phase: ph.key }
        menu :project_menu, parent, url,
             caption: OpenProject::Lpms3::Phases.menu_title_key(ph), icon: ph.icon, after: previous, if: visible,
             skip_permissions_check: true
        %i[ringkasan gerbang langkah register].each do |section|
          next if section == :register && ph.types.empty?

          menu :project_menu, OpenProject::Lpms3::Phases.menu_name(ph, section),
               url.merge(section == :ringkasan ? {} : { section: section.to_s }),
               caption: :"lpms3.phases.menu.#{section}", parent:, if: visible, skip_permissions_check: true
        end
        previous = parent
      end
    end

    config.to_prepare do
      OpenProject::Lpms3::Hooks
    end
  end
end
