module Lpms3
  # Jejak penambahan member otomatis oleh Lpms3::TimProyek (1.39).
  class AutoMember < ::ApplicationRecord
    self.table_name = "lpms3_auto_members"
    belongs_to :project
    belongs_to :user, class_name: "::User"
  end
end
