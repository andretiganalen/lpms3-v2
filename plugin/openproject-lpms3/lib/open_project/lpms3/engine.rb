require "open_project/plugins"

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
    end

    config.to_prepare do
      OpenProject::Lpms3::Hooks
    end
  end
end
