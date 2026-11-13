module Lpms3
  class FungsiUnitMap < ApplicationRecord
    self.table_name = "lpms3.fungsi_unit_map"
    belongs_to :unit, class_name: "Lpms3::OrgUnit", inverse_of: :mappings
    belongs_to :fungsi, class_name: "Lpms3::FungsiGenerik", inverse_of: :mappings
    belongs_to :fungsi_lama, class_name: "Lpms3::FungsiGenerik", optional: true
  end
end
