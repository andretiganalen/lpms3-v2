module Lpms3
  class OrgUnit < ApplicationRecord
    self.table_name = "lpms3.org_unit"
    belongs_to :structure, class_name: "Lpms3::OrgStructure", inverse_of: :units
    belongs_to :parent, class_name: "Lpms3::OrgUnit", optional: true
    has_many :children, class_name: "Lpms3::OrgUnit", foreign_key: :parent_id, inverse_of: :parent
    has_many :mappings, class_name: "Lpms3::FungsiUnitMap", foreign_key: :unit_id, inverse_of: :unit
    has_many :positions, class_name: "Lpms3::Position", foreign_key: :unit_id, inverse_of: :unit

    # Unit ini atau leluhurnya yang ber-grade tertentu (mis. "ES2"); nil bila tidak ada.
    def ancestor_with_grade(grade)
      node = self
      seen = 0
      while node && seen < 10
        return node if node.grade == grade

        node = node.parent
        seen += 1
      end
      nil
    end

    GRADE_LABEL = { "DIREKSI" => "Direktorat", "ES1" => "Divisi", "ES2" => "Bagian", "ES3" => "Seksi", "NON" => "Lainnya" }.freeze
  end
end
