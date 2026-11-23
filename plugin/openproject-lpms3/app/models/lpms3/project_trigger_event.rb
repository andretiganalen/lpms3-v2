# frozen_string_literal: true

module Lpms3
  # Log append-only pemicu LenO: tidak dapat diubah atau dihapus setelah tersimpan.
  class ProjectTriggerEvent < ::ApplicationRecord
    self.table_name = "lpms3_project_trigger_events"

    belongs_to :project_trigger, class_name: "Lpms3::ProjectTrigger"
    belongs_to :actor, class_name: "User", optional: true

    def readonly? = persisted?
    before_destroy { throw :abort }
  end
end
