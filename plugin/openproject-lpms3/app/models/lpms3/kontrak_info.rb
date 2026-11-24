# frozen_string_literal: true

module Lpms3
  # Data kontrak proyek di luar atribut proyek: nilai/tanggal awal, Go/No-Go, posisi Len, term of payment.
  class KontrakInfo < ::ApplicationRecord
    self.table_name = "lpms3.kontrak"
    self.primary_key = :project_id

    GO_NOGO = %w[BELUM GO NO_GO].freeze
    POSISI = ["Kontraktor Utama", "Sub-Kontraktor", "Retail"].freeze

    belongs_to :project, class_name: "::Project"
  end
end
