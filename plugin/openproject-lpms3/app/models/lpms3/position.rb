module Lpms3
  # Jabatan pada unit organisasi (1.39): Kepala (is_head), Admin (ADMIN_TEKNIS), dan Staf (STAF; menandai unit
  # tempat seorang pegawai berada, mis. Pimpro, agar atasan Eselon 2-nya dapat ditentukan).
  class Position < ::ApplicationRecord
    self.table_name = "lpms3.position"
    belongs_to :unit, class_name: "Lpms3::OrgUnit", inverse_of: :positions
    has_many :user_positions, class_name: "Lpms3::UserPosition", inverse_of: :position

    KIND = %w[KEPALA ADMIN STAF].freeze
    HEAD_GRADE = { "DIREKSI" => "DIREKSI", "ES1" => "STRUKTURAL_ES1", "ES2" => "STRUKTURAL_ES2", "ES3" => "STRUKTURAL_ES3" }.freeze

    def kind
      return "KEPALA" if is_head

      grade == "ADMIN_TEKNIS" ? "ADMIN" : "STAF"
    end

    # Posisi Kepala dan Admin untuk satu unit (dibuat bila belum ada; idempoten).
    def self.ensure_for!(unit, kind)
      raise ArgumentError, "Jenis jabatan tidak dikenal: #{kind}" unless KIND.include?(kind)

      head = kind == "KEPALA"
      grade = { "KEPALA" => HEAD_GRADE.fetch(unit.grade, "STAF"), "ADMIN" => "ADMIN_TEKNIS", "STAF" => "STAF" }.fetch(kind)
      title = { "KEPALA" => "Kepala", "ADMIN" => "Admin", "STAF" => "Staf" }.fetch(kind) + " #{unit.name}"
      find_by(unit_id: unit.id, is_head: head, grade:) || create!(unit:, is_head: head, grade:, title:, updated_at: Time.current)
    end
  end
end
