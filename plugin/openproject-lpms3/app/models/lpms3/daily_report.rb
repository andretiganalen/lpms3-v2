# frozen_string_literal: true

module Lpms3
  # Laporan harian per WO (sesuai mock-up): progres total, pelaksanaan, keterangan, kendala, dan foto.
  class DailyReport < ::ApplicationRecord
    self.table_name = "lpms3_daily_reports"
    EXECUTIONS = %w[sesuai kendala].freeze
    STATUSES = %w[draft terkirim].freeze

    belongs_to :work_package, class_name: "::WorkPackage"
    validates :report_date, presence: true
    validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    validates :execution, inclusion: { in: EXECUTIONS }
    validates :status, inclusion: { in: STATUSES }

    def sent? = status == "terkirim"
  end
end
