module Lpms3
  # Model baca-saja atas skema `lpms3` (db/020_lpms3_core.sql, db/040_lpms3_org_nota021.sql).
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true

    def readonly?
      true
    end
  end
end
