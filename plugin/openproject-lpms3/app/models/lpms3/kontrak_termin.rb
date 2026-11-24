# frozen_string_literal: true

module Lpms3
  # Termin pembayaran dari pemberi kerja: persen nilai kontrak dan syarat penagihan.
  class KontrakTermin < ::ApplicationRecord
    self.table_name = "lpms3.kontrak_termin"

    SYARAT = { "UANG_MUKA" => "Uang muka (jaminan uang muka aktif)", "PROGRES" => "Progres fisik ≥ x %",
               "AKTIVITAS" => "Aktivitas WBS selesai", "BAST" => "Serah terima (gerbang G3)", "MANUAL" => "Manual" }.freeze
    STATUS = { "RENCANA" => "Rencana", "DITAGIH" => "Ditagih", "DIBAYAR" => "Dibayar" }.freeze

    belongs_to :project, class_name: "::Project"
    belongs_to :wbs_node, class_name: "Lpms3::WbsNode", foreign_key: :syarat_wbs_node_id, optional: true
  end
end
