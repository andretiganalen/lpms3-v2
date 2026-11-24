# frozen_string_literal: true

module Lpms3
  # Kartu Member di Beranda Proyek (1.42): member proyek disusun menurut garis komando struktur organisasi aktif,
  # dari Direksi sampai Pimpro. Puncak = satu kotak Direksi (pejabat/admin direktorat); di bawahnya SEMUA Divisi
  # (Eselon 1) dari semua direktorat disejajarkan dalam satu baris, lalu Bagian (Eselon 2) dan Eselon 3.
  # Member tanpa jabatan aktif ditampilkan terpisah.
  module MemberHierarki
    GRADE_LABEL = { "DIREKSI" => "Direktorat", "ES1" => "Divisi · Eselon 1", "ES2" => "Bagian · Eselon 2",
                    "ES3" => "Eselon 3", "NON" => "Unit" }.freeze
    KIND_LABEL = { "KEPALA" => "Kepala", "ADMIN" => "Admin", "STAF" => "Staf" }.freeze
    KIND_ORDER = { "KEPALA" => 0, "ADMIN" => 1, "STAF" => 2 }.freeze
    PIMPRO = "Pimpro"

    Node = Struct.new(:unit, :children, :people, :fungsi, keyword_init: true) do
      def size = people.size + children.sum(&:size)
      def pimpro? = people.any? { |p| p[:pimpro] } || children.any?(&:pimpro?)
    end

    module_function

    # { roots: [Node], lainnya: [{user:, roles:, fungsi:}], total: n }
    def build(project)
      members = ::Member.where(project_id: project.id).includes(:principal, :roles).to_a
                        .select { |m| m.principal.is_a?(::User) && !m.principal.locked? }
      users = members.to_h { |m| [m.principal.id, [m.principal, m.roles.map(&:name).uniq]] }
      st = Hierarki.structure
      positions = if st
                    ::Lpms3::UserPosition.active_on.where(user_id: users.keys).includes(position: :unit).to_a
                                         .select { |up| up.position&.unit&.structure_id == st.id }
                  else
                    []
                  end
      groups = ::GroupUser.where(user_id: users.keys).joins("JOIN users g ON g.id = group_users.group_id")
                          .pluck(:user_id, "g.lastname").reject { |_, n| n.start_with?("Uji ") }
                          .group_by(&:first).transform_values { |l| l.map(&:last) }

      nodes = {}
      node_for = lambda do |unit|
        nodes[unit.id] ||= Node.new(unit:, children: [], people: [], fungsi: [])
      end
      placed = {}
      # Satu kursi per user: jabatan tertinggi (Kepala > Admin > Staf).
      positions.group_by(&:user_id).each do |uid, ups|
        up = ups.min_by { |x| KIND_ORDER.fetch(x.position.kind, 3) }
        user, roles = users[uid]
        node_for.(up.position.unit).people << { user:, roles:, kind: up.position.kind, title: up.position.title,
                                               pimpro: roles.include?(PIMPRO), fungsi: groups[uid] || [],
                                               jenis: up.assignment_type }
        placed[uid] = true
      end
      # Rantai induk sampai Direktorat agar garis komando lengkap.
      nodes.values.map(&:unit).each do |unit|
        child = node_for.(unit)
        parent = unit.parent
        while parent
          pn = node_for.(parent)
          pn.children << child unless pn.children.include?(child)
          child = pn
          parent = parent.parent
        end
      end
      fmap = ::Lpms3::FungsiUnitMap.where(structure_id: st&.id, unit_id: nodes.keys).includes(:fungsi).to_a.group_by(&:unit_id)
      nodes.each_value do |n|
        n.fungsi = (fmap[n.unit.id] || []).sort_by { |m| m.is_primary ? 0 : 1 }.map { |m| m.fungsi.name }.uniq
        n.children.sort_by! { |c| c.unit.code }
        n.people.sort_by! { |p| [KIND_ORDER.fetch(p[:kind], 3), p[:pimpro] ? 0 : 1, p[:user].name] }
      end
      # Sejajarkan semua fungsi sejak Level 1: direktorat dilebur menjadi satu kotak Direksi; anak-anaknya (Divisi Eselon 1,
      # atau unit lain yang langsung di bawah direktorat) menjadi satu baris di bawahnya.
      direksi = nodes.values.select { |n| n.unit.grade == "DIREKSI" }.sort_by { |n| n.unit.code }
      top = ::Lpms3::OrgUnit.new(code: "DIREKSI", name: "Direksi", grade: "DIREKSI")
      people = direksi.flat_map do |n|
        n.people.map { |p| p.merge(fungsi: [n.unit.name] + p[:fungsi]) }
      end
      level1 = direksi.flat_map(&:children)
      child_ids = nodes.values.flat_map { |n| n.children.map { |c| c.unit.id } }.to_set
      level1 += nodes.values.reject { |n| n.unit.grade == "DIREKSI" || child_ids.include?(n.unit.id) }
      root = Node.new(unit: top, children: level1.uniq.sort_by { |c| [c.unit.grade == "ES1" ? 0 : 1, c.unit.code] },
                      people:, fungsi: direksi.map { |n| n.unit.name })
      roots = nodes.empty? ? [] : [root]
      lainnya = users.reject { |uid, _| placed[uid] }.map { |uid, (u, r)| { user: u, roles: r, fungsi: groups[uid] || [] } }
                     .sort_by { |x| [x[:roles].include?(PIMPRO) ? 0 : 1, x[:roles].first.to_s, x[:user].name] }
      { roots:, lainnya:, total: users.size }
    end
  end
end
