# frozen_string_literal: true

module Lpms3
  # Status pengajuan WO (sesuai mock-up LenO Mobile): berjalan -> diajukan -> disetujui | ditolak (kembali ke PIC).
  class WoReview < ::ApplicationRecord
    self.table_name = "lpms3_wo_reviews"
    STATES = %w[berjalan diajukan ditolak disetujui].freeze

    belongs_to :work_package, class_name: "::WorkPackage"
    validates :state, inclusion: { in: STATES }

    def self.for(work_package) = find_or_create_by!(work_package_id: work_package.id)

    def editable? = %w[berjalan ditolak].include?(state)
    def locked? = state == "disetujui"
  end
end
