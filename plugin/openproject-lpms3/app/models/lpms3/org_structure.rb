module Lpms3
  class OrgStructure < ApplicationRecord
    self.table_name = "lpms3.org_structure"
    has_many :units, class_name: "Lpms3::OrgUnit", foreign_key: :structure_id, inverse_of: :structure

    scope :active, -> { where(status: "ACTIVE").order(effective_from: :desc) }
  end
end
