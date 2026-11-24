# frozen_string_literal: true

module Lpms3
  # Kartu Member di Beranda (1.42) — pohon garis komando berbasis orang, sesuai
  # docs/template-bop001/tampilan-widget-project-member.md:
  #
  #   Pejabat Direktur Operasional
  #   ├ Admin Direktur Operasional
  #   ├ Pejabat Eselon 1 <Fungsi>          (setiap fungsi yang terlibat; puncaknya tetap Direktur Operasional)
  #   │ ├ Admin / Spesialis / Staff Eselon 1 <Fungsi>
  #   │ └ Pejabat Eselon 2 <Fungsi>        (bisa lebih dari satu)
  #   │   └ Admin / Spesialis (Pimpro, Project Analis) / Staff Eselon 2 <Fungsi>
  #
  # Kedudukan dari jabatan aktif (lpms3.user_position); Spesialis = Staf yang berperan Pimpro, Project Analis, atau
  # Spesialis Pejabat Eselon 1/2. Kursi pejabat yang belum menjadi member tampil sebagai kursi kosong agar garis tetap utuh.
  module MemberHierarki
    PIMPRO = "Pimpro"
    SPESIALIS_ROLES = ["Pimpro", "Project Analis", "Spesialis Pejabat Eselon 1", "Spesialis Pejabat Eselon 2"].freeze
    KIND_ORDER = { "ADMIN" => 0, "SPESIALIS" => 1, "STAF" => 2 }.freeze
    KIND_LABEL = { "KEPALA" => "Pejabat", "ADMIN" => "Admin", "SPESIALIS" => "Spesialis", "STAF" => "Staff" }.freeze
    # Fungsi Generik siklus proyek didahulukan saat memberi nama kursi (Nota 021 memetakan banyak fungsi per unit).
    FUNGSI_PROYEK = %w[F-MPR F-PWP F-PRP F-MRS F-K3L FB-28 F-PMT F-PGD FB-16 FB-17 F-KEU F-RKS FB-14 F-PMS].freeze

    # label: teks kursi; person: {user:, roles:, pimpro:} atau nil (kursi kosong); children: [Node]
    Node = Struct.new(:label, :unit_name, :person, :children, :kind, :level, keyword_init: true) do
      def size = (person ? 1 : 0) + children.sum(&:size)
      def pimpro? = person&.dig(:pimpro) || children.any?(&:pimpro?)
    end

    module_function

    def build(project)
      members = ::Member.where(project_id: project.id).includes(:principal, :roles).to_a
                        .select { |m| m.principal.is_a?(::User) && !m.principal.locked? }
      users = members.to_h { |m| [m.principal.id, { user: m.principal, roles: m.roles.map(&:name).uniq }] }
      users.each_value { |u| u[:pimpro] = u[:roles].include?(PIMPRO) }
      st = Hierarki.structure
      return { roots: [], lainnya: users.values, total: users.size } unless st

      ups = ::Lpms3::UserPosition.active_on.where(user_id: users.keys).includes(position: :unit).to_a
                                 .select { |up| up.position&.unit&.structure_id == st.id }
      # Satu kursi per user: Kepala > Admin > Staf.
      seat = ups.group_by(&:user_id).transform_values { |l| l.min_by { |up| { "KEPALA" => 0, "ADMIN" => 1 }.fetch(up.position.kind, 2) } }

      dir_unit = Hierarki.unit_direksi_of_fungsi
      direksi = []
      es1 = Hash.new { |h, k| h[k] = { people: [], es2: Hash.new { |hh, kk| hh[kk] = [] } } }
      seat.each do |uid, up|
        unit = up.position.unit
        p = users[uid]
        kind = up.position.kind
        e1 = unit.grade == "ES1" ? unit : unit.ancestor_with_grade("ES1")
        e2 = if unit.grade == "ES2" then unit
             elsif unit.grade == "ES3" then unit.ancestor_with_grade("ES2")
             end
        if unit.grade == "DIREKSI" || e1.nil?
          direksi << [p, kind, unit]
        elsif e2
          es1[e1][:es2][e2] << [p, kind]
        else
          es1[e1][:people] << [p, kind]
        end
      end

      fungsi = fungsi_names(st, es1.keys + es1.values.flat_map { |v| v[:es2].keys })
      fname = ->(unit) { fungsi[unit.id] || unit.name }

      e1_nodes = es1.map do |unit, data|
        kepala = data[:people].find { |_, k| k == "KEPALA" }&.first
        others = data[:people].reject { |_, k| k == "KEPALA" }.map { |p, k| person_node(p, k, "Eselon 1", fname.(unit)) }
        # Bagian tanpa Pejabat Eselon 2 member: stafnya digantungkan ke Pejabat Eselon 2 lain di fungsi (Eselon 1) yang sama.
        heads = data[:es2].select { |_, list| list.any? { |_, k| k == "KEPALA" } }.keys.min_by(&:code)
        if heads
          data[:es2].each_key.to_a.each do |u2|
            next if u2 == heads || data[:es2][u2].any? { |_, k| k == "KEPALA" }

            data[:es2][heads].concat(data[:es2].delete(u2))
          end
        end
        e2_nodes = data[:es2].flat_map do |u2, list|
          kepalas = list.select { |_, k| k == "KEPALA" }.map(&:first)
          leafs = list.reject { |_, k| k == "KEPALA" }.map { |p, k| person_node(p, k, "Eselon 2", fname.(u2)) }
          (kepalas.presence || [nil]).each_with_index.map do |k2, i|
            Node.new(label: "Pejabat Eselon 2 #{fname.(u2)}", unit_name: u2.name, person: k2, kind: "KEPALA", level: 2,
                     children: i.zero? ? sort_leafs(leafs) : [])
          end
        end.sort_by { |n| [n.unit_name.to_s, n.person ? 0 : 1] }
        [unit, Node.new(label: "Pejabat Eselon 1 #{fname.(unit)}", unit_name: unit.name, person: kepala, kind: "KEPALA", level: 1,
                        children: sort_leafs(others) + e2_nodes)]
      end
      proyek_es1 = Hierarki.unit_eselon1_of_fungsi
      pwp_es1 = Hierarki.unit_eselon1_of_fungsi("F-PWP")
      e1_nodes = e1_nodes.sort_by { |u, _| [u.id == proyek_es1&.id ? 0 : (u.id == pwp_es1&.id ? 1 : 2), u.code] }.map(&:last)

      direktur = direksi.find { |_, k, u| k == "KEPALA" && u.id == dir_unit&.id }&.first
      dir_children = direksi.reject { |_, k, u| k == "KEPALA" && u.id == dir_unit&.id }.map do |p, k, u|
        own = u.id == dir_unit&.id
        Node.new(label: own ? "#{KIND_LABEL.fetch(k, 'Staff')} Direktur Operasional" : "#{KIND_LABEL.fetch(k, 'Staff')} #{u.name}",
                 unit_name: own ? nil : u.name, person: p, kind: k, level: 1, children: [])
      end
      root = Node.new(label: "Pejabat Direktur Operasional", unit_name: dir_unit&.name, person: direktur, kind: "KEPALA", level: 0,
                      children: dir_children.sort_by { |n| KIND_ORDER.fetch(n.kind, 3) } + e1_nodes)
      placed = seat.keys.to_set
      lainnya = users.reject { |uid, _| placed.include?(uid) }.values
                     .sort_by { |x| [x[:pimpro] ? 0 : 1, x[:roles].first.to_s, x[:user].name] }
      { roots: seat.empty? ? [] : [root], lainnya:, total: users.size }
    end

    def person_node(p, kind, eselon, fungsi)
      kind = "SPESIALIS" if kind == "STAF" && p[:roles].intersect?(SPESIALIS_ROLES)
      Node.new(label: "#{KIND_LABEL.fetch(kind, 'Staff')} #{eselon} #{fungsi}", person: p, kind:, level: 3, children: [])
    end

    def sort_leafs(list) = list.sort_by { |n| [KIND_ORDER.fetch(n.kind, 3), n.person&.dig(:pimpro) ? 0 : 1, n.person&.dig(:user)&.name.to_s] }

    # Nama Fungsi Generik per unit: pemetaan primer unit itu, atau unit di bawahnya (Divisi → Bagian).
    def fungsi_names(st, units)
      units.uniq.to_h do |u|
        ids = [u.id] + ::Lpms3::OrgUnit.where(parent_id: u.id).pluck(:id)
        m = ::Lpms3::FungsiUnitMap.where(structure_id: st.id, unit_id: ids).includes(:fungsi).to_a
                                  .min_by { |x| [FUNGSI_PROYEK.index(x.fungsi&.code) || 99, x.unit_id == u.id ? 0 : 1, x.is_primary ? 0 : 1, x.id] }
        [u.id, m&.fungsi&.name]
      end.compact
    end
  end
end
