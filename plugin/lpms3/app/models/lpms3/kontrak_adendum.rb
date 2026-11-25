# frozen_string_literal: true

module Lpms3
  # Adendum kontrak (SFR-025). Saat disahkan, nilai dan/atau tanggal selesai kontrak efektif di atribut proyek berubah.
  class KontrakAdendum < ::ApplicationRecord
    self.table_name = "lpms3.kontrak_adendum"

    belongs_to :project, class_name: "::Project"
    belongs_to :change_request, class_name: "::WorkPackage", optional: true
    belongs_to :creator, class_name: "::User", foreign_key: :created_by, optional: true
    belongs_to :pengesah, class_name: "::User", foreign_key: :disahkan_by, optional: true

    def disahkan? = status == "DISAHKAN"
  end
end
