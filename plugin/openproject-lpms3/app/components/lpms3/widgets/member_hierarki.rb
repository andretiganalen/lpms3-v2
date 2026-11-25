# frozen_string_literal: true

module Lpms3
  module Widgets
    # Pengganti kartu Member LPMS di Beranda semua workspace: pohon garis komando berbasis orang
    # (Direktur Operasional → Pejabat Eselon 1 tiap Fungsi → Admin/Spesialis/Staff → Pejabat Eselon 2 → …), setiap cabang
    # dapat dibuka/ditutup. Format: docs/template-bop001/tampilan-widget-project-member.md. Data: Lpms3::MemberHierarki.
    class MemberHierarki < ::Grids::WidgetComponent
      param :project

      def title = "Member proyek"

      def call
        widget_wrapper do |container|
          if current_user.allowed_in_project?(:view_members, project)
            container.with_footer { helpers.link_to("Lihat semua member", helpers.project_members_path(project)) }
            body(::Lpms3::MemberHierarki.build_for(project, current_user))
          else
            content_tag(:p, I18n.t("grids.widgets.not_available"), class: "lpms3-hint")
          end
        end
      end

      private

      def body(data)
        return content_tag(:p, "Belum ada member.", class: "lpms3-hint") if data[:total].zero?
        if data[:terbatas] && data[:roots].empty?
          return content_tag(:p, "Jabatan Anda belum tercatat di struktur; garis komando belum dapat ditampilkan.", class: "lpms3-hint")
        end

        safe_join([
          content_tag(:div, class: "lpms3-org__bar") do
            safe_join([
              content_tag(:span, data[:terbatas] ? "Garis komando Anda: atasan sampai Pejabat Direktur Operasional#{' dan bawahan Anda' if data[:roots].first&.size.to_i > 1}" : "#{data[:total]} member · garis komando dari Pejabat Direktur Operasional", class: "lpms3-org__meta"),
              content_tag(:button, "Buka semua", type: "button", class: "lpms3-btn", data: { lpms3_org: "open" }),
              content_tag(:button, "Tutup semua", type: "button", class: "lpms3-btn", data: { lpms3_org: "close" })
            ])
          end,
          (content_tag(:ul, safe_join(data[:roots].map { |n| node(n) }), class: "lpms3-tree", role: "tree") if data[:roots].any?),
          others(data[:lainnya])
        ].compact)
      end

      def row(n)
        p = n.person
        content_tag(:span, class: "lpms3-tree__row lpms3-tree__k-#{n.kind.to_s.downcase}#{' is-pimpro' if p&.dig(:pimpro)}#{' is-empty' unless p}") do
          safe_join([
            content_tag(:span, n.label, class: "lpms3-tree__seat"),
            (content_tag(:span, n.unit_name, class: "lpms3-tree__unit") if n.unit_name),
            if p
              safe_join([content_tag(:span, p[:user].name, class: "lpms3-tree__name"),
                         content_tag(:span, safe_join(p[:roles].map { |r| content_tag(:span, r, class: "lpms3-chip#{' lpms3-chip--ok' if %w[Pimpro Project\ Analis].include?(r)}") }, " "),
                                     class: "lpms3-tree__roles")])
            else
              content_tag(:span, "kursi belum menjadi member proyek", class: "lpms3-tree__vacant")
            end,
            (content_tag(:span, "#{n.size - (p ? 1 : 0)} di bawah", class: "lpms3-tree__count") if n.children.any?)
          ].compact)
        end
      end

      def node(n)
        inner = if n.children.any?
                  content_tag(:details, open: n.level < 2 || n.pimpro?, class: "lpms3-tree__branch") do
                    safe_join([content_tag(:summary, row(n)), content_tag(:ul, safe_join(n.children.map { |c| node(c) }), role: "group")])
                  end
                else
                  row(n)
                end
        content_tag(:li, inner, class: "lpms3-tree__item", role: "treeitem")
      end

      def others(list)
        return nil if list.empty?

        content_tag(:details, class: "lpms3-org__others") do
          safe_join([
            content_tag(:summary, "Member tanpa jabatan aktif (#{list.size}) — isi di Administrasi → Jabatan Pengguna"),
            content_tag(:ul) do
              safe_join(list.map do |x|
                content_tag(:li) do
                  safe_join([content_tag(:span, x[:user].name, class: "lpms3-tree__name"), " ",
                             safe_join(x[:roles].map { |r| content_tag(:span, r, class: "lpms3-chip") }, " ")])
                end
              end)
            end
          ])
        end
      end
    end
  end
end
