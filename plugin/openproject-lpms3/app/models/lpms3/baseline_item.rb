# frozen_string_literal: true

module Lpms3
  class BaselineItem < ::ApplicationRecord
    self.table_name = "lpms3.baseline_item"
    self.primary_key = %i[baseline_id wbs_node_id]

    belongs_to :baseline, class_name: "Lpms3::Baseline"
  end
end
