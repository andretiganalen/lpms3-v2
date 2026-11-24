# frozen_string_literal: true

module Lpms3
  # Rekam aktivitas saat mencapai 100 % (pekerjaan selesai dibekukan).
  class WbsDoneSnapshot < ::ApplicationRecord
    self.table_name = "lpms3.wbs_done_snapshot"
    self.primary_key = :wbs_node_id
  end
end
