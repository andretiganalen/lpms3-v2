module Lpms3
  class FungsiGenerik < ApplicationRecord
    self.table_name = "lpms3.fungsi_generik"
    belongs_to :induk, class_name: "Lpms3::FungsiGenerik", optional: true
    has_many :mappings, class_name: "Lpms3::FungsiUnitMap", foreign_key: :fungsi_id, inverse_of: :fungsi
  end
end
