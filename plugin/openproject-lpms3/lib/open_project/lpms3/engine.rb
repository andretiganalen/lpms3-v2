require "open_project/plugins"
require "open_project/lpms3/features"
require "open_project/lpms3/branding"
require "open_project/lpms3/phases"
require "open_project/lpms3/aspects"
require "open_project/lpms3/fx"
require "open_project/lpms3/procurement"
require "open_project/lpms3/pdf"

module OpenProject::Lpms3
  class Engine < ::Rails::Engine
    engine_name :openproject_lpms3

    include OpenProject::Plugins::ActsAsOpEngine

    # Didaftarkan di to_prepare (seperti izin inti) karena OpenProject::AccessControl baru dapat di-autoload setelah initializer plugin.
    config.to_prepare do
      OpenProject::AccessControl.map do |map|
        unless OpenProject::AccessControl.permissions.any? { |pm| pm.name == :manage_currency_rates }
          map.permission :manage_currency_rates,
                         { "lpms3/currencies": %i[create_currency update_currency create_rate fetch apply_budget] },
                         permissible_on: :global,
                         require: :loggedin
        end
      end
    end

    register "openproject-lpms3",
             author_url: "https://github.com/andretiganalen/lpms3-v2" do
      # Mata uang & kurs: izin global untuk peran Keuangan (peran global di Administrasi -> Peran). Admin selalu boleh.

      menu :admin_menu,
           :lpms3_currencies_admin,
           { controller: "/lpms3/currencies", action: :index },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.currencies.menu",
           icon: "gear"

      menu :global_menu,
           :lpms3_currencies,
           { controller: "/lpms3/currencies", action: :index },
           if: Proc.new { User.current.logged? },
           caption: :"lpms3.currencies.menu",
           icon: "credit-card",
           after: :projects

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
        sections = %i[ringkasan gerbang langkah]
        sections << :aspek if ph.key == "inisiasi"
        sections << :register
        sections.each do |section|
          next if section == :register && ph.types.empty?

          menu :project_menu, OpenProject::Lpms3::Phases.menu_name(ph, section),
               url.merge(section == :ringkasan ? {} : { section: section.to_s }),
               caption: :"lpms3.phases.menu.#{section}", parent:, if: visible, skip_permissions_check: true
        end
        previous = parent
      end

      # Eksekusi Item Pengadaan: ringkasan + tiga sub-fase (anak menu fase Eksekusi) + menu global lintas project.
      eks = OpenProject::Lpms3::Phases.menu_name(OpenProject::Lpms3::Phases.find("eksekusi"))
      menu :project_menu, :lpms3_fase_eksekusi_pengadaan, { controller: "/lpms3/procurement", action: :show },
           caption: :"lpms3.procurement.menu", parent: eks, if: visible, skip_permissions_check: true
      %w[pr buyer penyelesaian].each do |sub|
        menu :project_menu, :"lpms3_fase_eksekusi_pengadaan_#{sub}", { controller: "/lpms3/procurement", action: :show, sub: },
             caption: :"lpms3.procurement.sub.#{sub}.menu", parent: eks, if: visible, skip_permissions_check: true
      end
      menu :global_menu, :lpms3_procurement, { controller: "/lpms3/procurement", action: :show },
           if: Proc.new { User.current.logged? }, caption: :"lpms3.procurement.menu", icon: "package", after: :lpms3_currencies
      menu :global_menu, :lpms3_portofolio, { controller: "/lpms3/portfolio", action: :show },
           if: Proc.new { User.current.logged? }, caption: "Portofolio LPMS3", icon: "graph", after: :lpms3_procurement
      menu :global_menu, :lpms3_tugas, { controller: "/lpms3/tasks", action: :index },
           if: Proc.new { User.current.logged? }, caption: ->(_project) { n = ::Lpms3::Inbox.count(User.current); n.positive? ? "Tugas & Notifikasi (#{n})" : "Tugas & Notifikasi" }, icon: "bell", after: :lpms3_procurement
    end

    config.to_prepare do
      OpenProject::Lpms3::Hooks
      # Gerbang Eksekusi Item Pengadaan: berlandaskan Budget, tiga sub-fase (PR, Buyer sampai kontrak, milestone sampai BA).
      unless WorkPackage.instance_variable_get(:@lpms3_procurement_gate)
        WorkPackage.instance_variable_set(:@lpms3_procurement_gate, true)
        WorkPackage.validate do
          OpenProject::Lpms3::Procurement.gate(self).each do |code, opts|
            errors.add(:base, I18n.t("lpms3.procurement.gate.#{code}", **(opts || {})))
          end
        end
      end
    end
  end
end
