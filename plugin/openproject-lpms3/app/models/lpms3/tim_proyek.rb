module Lpms3
  # Member proyek berjenjang dari Direksi (1.39, docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md §3).
  #  - Tim default: Direktur Operasi + Admin-nya, Pejabat Eselon 1 Fungsi Pelaksanaan Proyek + Admin-nya.
  #  - Setiap Pimpro: Pejabat Eselon 2 atasannya ikut menjadi member.
  # Hanya menambah peran, tidak pernah menghapus member/peran. Setiap penambahan tercatat di lpms3_auto_members.
  module TimProyek
    ROLE_DIREKSI = "Direksi"
    ROLE_ADMIN_DIREKSI = "Admin Direksi"
    ROLE_ESELON1 = "Pejabat Eselon 1"
    ROLE_ADMIN_ESELON1 = "Admin Pejabat Eselon 1"
    ROLE_ESELON2 = "Pejabat Eselon 2"
    ROLE_PIMPRO = "Pimpro"
    # Fungsi Pengawasan Proyek memantau semua proyek (BOP-001 §5.4): Pejabat Eselon 1 sebagai Approver CCM, Admin (menunjuk
    # Project Analis saat Kick-Off) dan Pejabat Eselon 2 unit primer F-PWP sebagai peran Fungsi Pengawasan Proyek (1.42).
    FUNGSI_PENGAWASAN = "F-PWP"
    ROLE_APPROVER_CCM = "Approver CCM"
    ROLE_PENGAWAS = "Fungsi Pengawasan Proyek"
    PIMPRO_FIELD = "Pimpro"

    Result = Struct.new(:added, :present, :warnings, keyword_init: true)

    module_function

    # Daftar [user, nama peran, alasan] yang seharusnya ada di proyek + peringatan bila jabatan belum terisi.
    def desired(project)
      out = []
      warnings = []
      es1 = Hierarki.unit_eselon1_of_fungsi
      dir = es1&.ancestor_with_grade("DIREKSI")
      warnings << "Unit Eselon 1 Fungsi Pelaksanaan Proyek tidak ditemukan di struktur aktif." unless es1
      [[dir, "KEPALA", ROLE_DIREKSI, "Direktur"], [dir, "ADMIN", ROLE_ADMIN_DIREKSI, "Admin Direktur"],
       [es1, "KEPALA", ROLE_ESELON1, "Pejabat Eselon 1"], [es1, "ADMIN", ROLE_ADMIN_ESELON1, "Admin Pejabat Eselon 1"]].each do |unit, kind, role, label|
        next unless unit

        users = Hierarki.holders(unit, kind)
        warnings << "Jabatan #{label} #{unit.name} belum diisi." if users.empty?
        users.each { |u| out << [u, role, "Tim default: #{label} #{unit.name}"] }
      end

      pwp1 = Hierarki.unit_eselon1_of_fungsi(FUNGSI_PENGAWASAN)
      pwp2 = Hierarki.unit_primer_of_fungsi(FUNGSI_PENGAWASAN)
      pwp2 = nil if pwp2 && pwp2.id == pwp1&.id
      [[pwp1, "KEPALA", ROLE_APPROVER_CCM, "Pejabat Eselon 1"], [pwp1, "ADMIN", ROLE_PENGAWAS, "Admin Pejabat Eselon 1"],
       [pwp2, "KEPALA", ROLE_PENGAWAS, "Pejabat Eselon 2"]].each do |unit, kind, role, label|
        next unless unit && ::ProjectRole.exists?(name: role)

        Hierarki.holders(unit, kind).each { |u| out << [u, role, "Fungsi Pengawasan Proyek: #{label} #{unit.name}"] }
      end

      pimpros(project).each do |p|
        es2 = Hierarki.unit_eselon2_of(p)
        if es2.nil?
          warnings << "Unit Eselon 2 Pimpro #{p.name} belum diketahui (jabatan pengguna belum diisi)."
          next
        end
        atasan = Hierarki.atasan_eselon2_of(p)
        warnings << "Jabatan Kepala #{es2.name} (atasan Pimpro #{p.name}) belum diisi." if atasan.empty? && Hierarki.holders(es2, "KEPALA").none? { |u| u.id == p.id }
        atasan.each { |u| out << [u, ROLE_ESELON2, "Atasan Eselon 2 Pimpro #{p.name} (#{es2.name})"] }
      end
      [out, warnings]
    end

    # Pimpro proyek: atribut proyek "Pimpro" dan member berperan Pimpro.
    def pimpros(project)
      ids = []
      if (cf = ::ProjectCustomField.find_by(name: PIMPRO_FIELD))
        ids += ::CustomValue.where(customized_type: "Project", customized_id: project.id, custom_field_id: cf.id)
                            .pluck(:value).map(&:to_i)
      end
      if (role = ::ProjectRole.find_by(name: ROLE_PIMPRO))
        ids += ::Member.where(project_id: project.id).joins(:member_roles)
                       .where(member_roles: { role_id: role.id }).pluck(:user_id)
      end
      ::User.active.where(id: ids.uniq.select(&:positive?)).to_a
    end

    def sync!(project)
      return Result.new(added: [], present: [], warnings: []) if project.nil? || project.templated?

      list, warnings = desired(project)
      added = []
      present = []
      without_hooks do
        list.each do |user, role_name, alasan|
          role = ::ProjectRole.find_by(name: role_name)
          next warnings << "Peran proyek \"#{role_name}\" belum ada (jalankan seed 80_tim_proyek)." unless role

          member = ::Member.find_or_initialize_by(project:, principal: user)
          if member.persisted? && member.roles.include?(role)
            present << [user, role_name]
            next
          end
          member.roles = (member.roles.to_a + [role]).uniq
          member.save!
          ::Lpms3::AutoMember.create!(project_id: project.id, user_id: user.id, role_name:, alasan:)
          added << [user, role_name, alasan]
        end
      end
      Result.new(added:, present:, warnings: warnings.uniq)
    end

    # Dipanggil dari callback (Member/MemberRole/CustomValue). Galat dicatat, tidak menggagalkan aksi pengguna.
    def sync_later(project_id)
      return if Thread.current[:lpms3_tim_proyek_sync]

      project = ::Project.find_by(id: project_id)
      sync!(project) if project
    rescue StandardError => e
      Rails.logger.error("[lpms3] sinkron tim proyek #{project_id} gagal: #{e.class}: #{e.message}")
    end

    def without_hooks
      prev = Thread.current[:lpms3_tim_proyek_sync]
      Thread.current[:lpms3_tim_proyek_sync] = true
      yield
    ensure
      Thread.current[:lpms3_tim_proyek_sync] = prev
    end

    def pimpro_role_id = ::ProjectRole.find_by(name: ROLE_PIMPRO)&.id
    def pimpro_field_id = ::ProjectCustomField.find_by(name: PIMPRO_FIELD)&.id
  end
end
