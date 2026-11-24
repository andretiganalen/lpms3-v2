require "open_project/plugins"
require "open_project/lpms3/features"
require "open_project/lpms3/branding"
require "open_project/lpms3/phases"
require "open_project/lpms3/aspects"
require "open_project/lpms3/fx"
require "open_project/lpms3/procurement"
require "open_project/lpms3/pdf"
require "open_project/lpms3/header_summary"

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
        # Pemicu LenO (1.37): registrasi dan persetujuan proyek baru. Diperiksa lewat keanggotaan peran global
        # (Lpms3::ProjectTrigger.holds_global_permission?), bukan allowed_globally?, agar admin tidak otomatis lolos.
        %i[lpms3_register_project_trigger lpms3_approve_project_trigger].each do |perm|
          next if OpenProject::AccessControl.permissions.any? { |pm| pm.name == perm }

          map.permission perm, { "lpms3/pemicu": [] }, permissible_on: :global, require: :loggedin
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
           :lpms3_jabatan,
           { controller: "/lpms3/admin/jabatan", action: :index },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.jabatan.menu",
           icon: "people"

      menu :admin_menu,
           :lpms3_pemicu_leno,
           { controller: "/lpms3/admin/pemicu_leno", action: :index },
           if: Proc.new { User.current.admin? },
           caption: :"lpms3.pemicu_leno.menu",
           icon: "inbox"

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
      # Kelas bawaan "<nama>-menu-item" harus tetap ada (sorotan menu) saat menambah kelas grup sidebar.
      grp_cls = ->(name, extra) { "#{name.to_s.dasherize}-menu-item #{extra}" }
      visible = ->(project) { project.module_enabled?("work_package_tracking") && User.current.allowed_in_project?(:view_work_packages, project) }
      previous = :overview
      OpenProject::Lpms3::Phases::ALL.each do |ph|
        parent = OpenProject::Lpms3::Phases.menu_name(ph)
        url = { controller: "/lpms3/phases", action: :show, phase: ph.key }
        # Anak dinamis = daftar Langkah BOP-001 project (dipindah JS ke bawah submenu "Langkah BOP-001").
        menu :project_menu, parent, url,
             caption: OpenProject::Lpms3::Phases.menu_title_key(ph), icon: ph.icon, after: previous, if: visible,
             skip_permissions_check: true, children: ->(project) { OpenProject::Lpms3::Phases.step_menu_items(project, ph) }
        # Submenu 1 "Ringkasan Fase" (kepala grup) + anggota grupnya; submenu 2 "Langkah BOP-001" didaftarkan terakhir.
        menu :project_menu, OpenProject::Lpms3::Phases.menu_name(ph, :ringkasan), url,
             caption: :"lpms3.phases.menu.ringkasan_fase", parent:, if: visible, skip_permissions_check: true,
             html: { class: grp_cls.(OpenProject::Lpms3::Phases.menu_name(ph, :ringkasan), "lpms3-grp-head lpms3-grp-head--ringkasan") }
        sections = %i[gerbang]
        sections << :aspek if ph.key == "inisiasi"
        sections << :register unless ph.types.empty?
        sections.each do |section|
          menu :project_menu, OpenProject::Lpms3::Phases.menu_name(ph, section), url.merge(section: section.to_s),
               caption: :"lpms3.phases.menu.#{section}", parent:, if: visible, skip_permissions_check: true,
               html: { class: grp_cls.(OpenProject::Lpms3::Phases.menu_name(ph, section), "lpms3-grp-item") }
        end
        previous = parent
      end

      # Editor WBS & Bobot (1.40) di fase Perencanaan.
      menu :project_menu, :lpms3_fase_perencanaan_wbs, { controller: "/lpms3/wbs", action: :show },
           caption: :"lpms3.wbs.menu", parent: OpenProject::Lpms3::Phases.menu_name(OpenProject::Lpms3::Phases.find("perencanaan")),
           if: visible, skip_permissions_check: true, html: { class: grp_cls.(:lpms3_fase_perencanaan_wbs, "lpms3-grp-item") }

      # Eksekusi Item Pengadaan: ringkasan + tiga sub-fase (anak menu fase Eksekusi) + menu global lintas project.
      eks = OpenProject::Lpms3::Phases.menu_name(OpenProject::Lpms3::Phases.find("eksekusi"))
      menu :project_menu, :lpms3_fase_eksekusi_pengadaan, { controller: "/lpms3/procurement", action: :show },
           caption: :"lpms3.procurement.menu", parent: eks, if: visible, skip_permissions_check: true,
           html: { class: grp_cls.(:lpms3_fase_eksekusi_pengadaan, "lpms3-grp-item") }
      %w[pr buyer penyelesaian].each do |sub|
        menu :project_menu, :"lpms3_fase_eksekusi_pengadaan_#{sub}", { controller: "/lpms3/procurement", action: :show, sub: },
             caption: :"lpms3.procurement.sub.#{sub}.menu", parent: eks, if: visible, skip_permissions_check: true,
             html: { class: grp_cls.(:"lpms3_fase_eksekusi_pengadaan_#{sub}", "lpms3-grp-item lpms3-grp-item--sub") }
      end
      # Monitoring Kontrak awal (1.42): grup Ringkasan Fase Inisiasi + menu global lintas proyek.
      menu :project_menu, :lpms3_fase_inisiasi_kontrak, { controller: "/lpms3/kontrak", action: :show },
           caption: :"lpms3.kontrak.menu", parent: OpenProject::Lpms3::Phases.menu_name(OpenProject::Lpms3::Phases.find("inisiasi")),
           if: visible, skip_permissions_check: true, html: { class: grp_cls.(:lpms3_fase_inisiasi_kontrak, "lpms3-grp-item") }
      menu :global_menu, :lpms3_kontrak, { controller: "/lpms3/kontrak", action: :index },
           if: Proc.new { User.current.logged? }, caption: :"lpms3.kontrak.menu_global", icon: "file", after: :lpms3_procurement
      # Submenu 2 setiap fase: "Langkah BOP-001" (dropdown berisi langkah urut; isinya anak dinamis menu fase).
      OpenProject::Lpms3::Phases::ALL.each do |ph|
        menu :project_menu, OpenProject::Lpms3::Phases.menu_name(ph, :langkah),
             { controller: "/lpms3/phases", action: :show, phase: ph.key, section: "langkah" },
             caption: :"lpms3.phases.menu.langkah_bop", parent: OpenProject::Lpms3::Phases.menu_name(ph), if: visible,
             skip_permissions_check: true, html: { class: grp_cls.(OpenProject::Lpms3::Phases.menu_name(ph, :langkah), "lpms3-grp-head lpms3-grp-head--langkah") }
      end
      menu :global_menu, :lpms3_procurement, { controller: "/lpms3/procurement", action: :show },
           if: Proc.new { User.current.logged? }, caption: :"lpms3.procurement.menu", icon: "package", after: :lpms3_currencies
      menu :global_menu, :lpms3_portofolio, { controller: "/lpms3/portfolio", action: :show },
           if: Proc.new { User.current.logged? }, caption: "Portofolio LPMS3", icon: "graph", after: :lpms3_procurement
      menu :global_menu, :lpms3_tugas, { controller: "/lpms3/tasks", action: :index },
           if: Proc.new { User.current.logged? }, caption: ->(_project) { n = ::Lpms3::Inbox.count(User.current); n.positive? ? "Tugas & Notifikasi (#{n})" : "Tugas & Notifikasi" }, icon: "bell", after: :lpms3_procurement
    end

    config.to_prepare do
      # Member berjenjang (1.39): saat Pimpro ditetapkan (peran Pimpro atau atribut proyek "Pimpro"), Pejabat Eselon 2
      # atasannya dan tim default Direksi/Eselon 1 ditambahkan. Lpms3::TimProyek menahan rekursi dan menelan galat.
      unless ::MemberRole.instance_variable_get(:@lpms3_tim_proyek)
        ::MemberRole.instance_variable_set(:@lpms3_tim_proyek, true)
        ::MemberRole.after_commit(on: :create) do
          next unless role_id == ::Lpms3::TimProyek.pimpro_role_id

          pid = member&.project_id
          ::Lpms3::TimProyek.sync_later(pid) if pid
        end
        ::CustomValue.after_commit(on: %i[create update]) do
          next unless customized_type == "Project" && value.present?
          next unless custom_field_id == ::Lpms3::TimProyek.pimpro_field_id

          ::Lpms3::TimProyek.sync_later(customized_id)
        end
      end
      OpenProject::Lpms3::Hooks
      # Beranda Proyek (1.42): kartu Member diganti bagan garis komando untuk workspace "project".
      unless ::Grids::WidgetGridComponent.instance_variable_get(:@lpms3_member_hierarki)
        ::Grids::WidgetGridComponent.instance_variable_set(:@lpms3_member_hierarki, true)
        ::Grids::WidgetGridComponent.prepend(Module.new do
          def build_widget(widget_class, *widget_args, **system_arguments)
            proj = widget_args.first
            # Semua workspace (proyek, program, portofolio) memakai tampilan yang sama.
            if widget_class == ::Grids::Widgets::Members && proj.is_a?(::Project)
              widget_class = ::Lpms3::Widgets::MemberHierarki
            end
            super
          end
        end)
      end
      # Baseline WBS (1.41): CR (BFR-001) Disetujui mengaktifkan draft baseline; Ditolak menandai draft REJECTED.
      unless WorkPackage.instance_variable_get(:@lpms3_baseline_cr)
        WorkPackage.instance_variable_set(:@lpms3_baseline_cr, true)
        WorkPackage.after_commit(on: :update) do
          next unless saved_change_to_status_id?

          ::Lpms3::WbsBaseline.on_cr_status_change(self)
        rescue StandardError => e
          Rails.logger.error("[LPMS3] baseline CR ##{id}: #{e.class}: #{e.message}")
        end
      end
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
