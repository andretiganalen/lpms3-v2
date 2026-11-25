# frozen_string_literal: true

module Lpms3
  # Distribusi rencana per periode per aktivitas untuk satu baseline (Kurva-S).
  class ScurvePlan < ::ApplicationRecord
    self.table_name = "lpms3.scurve_plan"
    self.primary_key = %i[baseline_id wbs_node_id period_start granularity]
  end
end
