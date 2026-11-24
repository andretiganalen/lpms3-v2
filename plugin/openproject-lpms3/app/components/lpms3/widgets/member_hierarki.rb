# frozen_string_literal: true

module Lpms3
  module Widgets
    # Pengganti kartu Member OpenProject di Beranda semua workspace: bagan garis komando member dari Direksi sampai Pimpro,
    # semua fungsi sejajar sejak Eselon 1, setiap cabang dapat dibuka/ditutup. Lihat Lpms3::MemberHierarki.
    class MemberHierarki < ::Grids::WidgetComponent
      param :project

      def title = "Member — garis komando"

      def call
        widget_wrapper do |container|
          if current_user.allowed_in_project?(:view_members, project)
            container.with_footer { helpers.link_to("Lihat semua member", helpers.project_members_path(project)) }
            body(::Lpms3::MemberHierarki.build(project))
          else
            content_tag(:p, I18n.t("grids.widgets.not_available"), class: "lpms3-hint")
          end
        end
      end

      private

      def body(data)
        return content_tag(:p, "Belum ada member.", class: "lpms3-hint") if data[:total].zero?

        safe_join([
          content_tag(:div, class: "lpms3-org__bar") do
            safe_join([
              content_tag(:span, "#{data[:total]} member · garis komando Direksi → Eselon 1 (semua fungsi sejajar) → Eselon 2 → Pimpro", class: "lpms3-org__meta"),
              content_tag(:button, "Buka semua", type: "button", class: "lpms3-btn", data: { lpms3_org: "open" }),
              content_tag(:button, "Tutup semua", type: "button", class: "lpms3-btn", data: { lpms3_org: "close" })
            ])
          end,
          (content_tag(:div, class: "lpms3-org__scroll") { content_tag(:ul, safe_join(data[:roots].map { |n| node(n, 0) }), class: "lpms3-org__tree") } if data[:roots].any?),
          others(data[:lainnya])
        ].compact)
      end

      def node(n, depth)
        card = content_tag(:div, class: "lpms3-org__card#{' is-pimpro' if n.pimpro?}") do
          safe_join([
            content_tag(:span, ::Lpms3::MemberHierarki::GRADE_LABEL.fetch(n.unit.grade, n.unit.grade), class: "lpms3-org__grade"),
            content_tag(:strong, n.unit.name, class: "lpms3-org__unit", title: n.unit.code),
            (content_tag(:span, n.fungsi.first(n.unit.grade == "DIREKSI" ? 5 : 2).join(" · "), class: "lpms3-org__fungsi") if n.fungsi.any?),
            (content_tag(:ul, safe_join(n.people.map { |p| person(p) }), class: "lpms3-org__people") if n.people.any?),
            (content_tag(:span, "#{n.size - n.people.size} member di bawah", class: "lpms3-org__count") if n.children.any?)
          ].compact)
        end
        inner = if n.children.any?
                  content_tag(:details, open: true, class: "lpms3-org__branch") do
                    safe_join([content_tag(:summary, card, "aria-label": "#{n.unit.name} — buka/tutup cabang"),
                               content_tag(:ul, safe_join(n.children.map { |c| node(c, depth + 1) }))])
                  end
                else
                  card
                end
        content_tag(:li, inner, class: "lpms3-org__node lpms3-org__lvl-#{n.unit.grade.downcase}")
      end

      def person(p)
        content_tag(:li, class: "lpms3-org__person#{' is-pimpro' if p[:pimpro]}") do
          safe_join([
            content_tag(:span, ::Lpms3::MemberHierarki::KIND_LABEL.fetch(p[:kind], p[:kind]) +
                               (p[:jenis] && p[:jenis] != "DEFINITIF" ? " (#{p[:jenis]})" : ""), class: "lpms3-org__kind"),
            content_tag(:span, p[:user].name, class: "lpms3-org__name"),
            content_tag(:span, safe_join(p[:roles].map { |r| content_tag(:span, r, class: "lpms3-chip#{' lpms3-chip--ok' if r == 'Pimpro'}") }, " "),
                        class: "lpms3-org__roles"),
            (content_tag(:span, p[:fungsi].first(2).join(" · "), class: "lpms3-org__pfungsi") if p[:fungsi].any?)
          ].compact)
        end
      end

      def others(list)
        return nil if list.empty?

        content_tag(:details, class: "lpms3-org__others") do
          safe_join([
            content_tag(:summary, "Member tanpa jabatan aktif (#{list.size}) — isi di Administrasi → Jabatan Pengguna"),
            content_tag(:ul) do
              safe_join(list.map do |x|
                content_tag(:li) do
                  safe_join([content_tag(:span, x[:user].name, class: "lpms3-org__name"), " ",
                             safe_join(x[:roles].map { |r| content_tag(:span, r, class: "lpms3-chip") }, " "),
                             (content_tag(:small, " #{x[:fungsi].first(2).join(' · ')}") if x[:fungsi].any?)].compact)
                end
              end)
            end
          ])
        end
      end
    end
  end
end
