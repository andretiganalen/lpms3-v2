module Lpms3
  class OrgUnit < ApplicationRecord
    self.table_name = "lpms3.org_unit"
    belongs_to :structure, class_name: "Lpms3::OrgStructure", inverse_of: :units
    belongs_to :parent, class_name: "Lpms3::OrgUnit", optional: true
    has_many :children, class_name: "Lpms3::OrgUnit", foreign_key: :parent_id, inverse_of: :parent
    has_many :mappings, class_name: "Lpms3::FungsiUnitMap", foreign_key: :unit_id, inverse_of: :unit

    GRADE_LABEL = { "DIREKSI" => "Direktorat", "ES1" => "Divisi", "ES2" => "Bagian", "ES3" => "Seksi", "NON" => "Lainnya" }.freeze
  end
end
