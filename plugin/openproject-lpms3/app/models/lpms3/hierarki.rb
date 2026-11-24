module Lpms3
  # Resolver hierarki jabatan dari struktur organisasi aktif + lpms3.user_position (1.39).
  # Direksi -> Eselon 1 (Divisi) -> Eselon 2 (Bagian). Plt/Plh yang berlaku dihitung sebagai pemegang jabatan.
  module Hierarki
    # Fungsi Pelaksanaan Proyek: unit Eselon 1-nya dan Direktorat di atasnya menjadi tim default setiap proyek.
    FUNGSI_PROYEK = "F-MPR"

    module_function

    def structure = ::Lpms3::OrgStructure.active.first

    # Pemegang aktif jabatan jenis tertentu ("KEPALA", "ADMIN", "STAF") pada unit; urut DEFINITIF dulu.
    def holders(unit, kind, date: Date.current)
      return [] unless unit

      pos_ids = unit.positions.select { |p| p.kind == kind }.map(&:id)
      return [] if pos_ids.empty?

      ups = ::Lpms3::UserPosition.active_on(date).where(position_id: pos_ids).includes(:user).to_a
      ups.sort_by { |up| [up.assignment_type == "DEFINITIF" ? 0 : 1, up.valid_from] }
         .map(&:user).select { |u| u&.active? }.uniq
    end

    # Unit tempat user memegang jabatan aktif (struktur aktif).
    def units_of(user, date: Date.current)
      st = structure
      return [] unless st && user

      ::Lpms3::UserPosition.active_on(date).where(user_id: user.id).includes(position: :unit)
                           .map { |up| up.position.unit }.select { |u| u.structure_id == st.id }.uniq
    end

    # Unit Eselon 2 user: unit jabatannya (atau leluhurnya) yang ber-grade ES2. Kepala unit ES2 itu adalah atasannya,
    # kecuali user sendiri kepala unit tersebut.
    def unit_eselon2_of(user)
      units_of(user).filter_map { |u| u.ancestor_with_grade("ES2") }.first
    end

    def atasan_eselon2_of(user)
      holders(unit_eselon2_of(user), "KEPALA").reject { |u| u.id == user.id }
    end

    # Unit Eselon 1 sebuah Fungsi Generik (pemetaan primer Nota 021, naik ke ES1).
    def unit_eselon1_of_fungsi(code = FUNGSI_PROYEK)
      st = structure
      fungsi = ::Lpms3::FungsiGenerik.find_by(code:)
      return nil unless st && fungsi

      maps = ::Lpms3::FungsiUnitMap.where(structure_id: st.id, fungsi_id: fungsi.id).includes(:unit)
                                   .order(is_primary: :desc, id: :asc)
      maps.filter_map { |m| m.unit.ancestor_with_grade("ES1") }.first
    end

    # Unit primer (pemetaan Nota 021) sebuah Fungsi Generik, mis. F-PWP → Bagian Operation Monitoring & Evaluation (ES2).
    def unit_primer_of_fungsi(code)
      st = structure
      fungsi = ::Lpms3::FungsiGenerik.find_by(code:)
      return nil unless st && fungsi

      ::Lpms3::FungsiUnitMap.where(structure_id: st.id, fungsi_id: fungsi.id).includes(:unit).order(is_primary: :desc, id: :asc).first&.unit
    end

    def unit_direksi_of_fungsi(code = FUNGSI_PROYEK)
      unit_eselon1_of_fungsi(code)&.ancestor_with_grade("DIREKSI")
    end
  end
end
