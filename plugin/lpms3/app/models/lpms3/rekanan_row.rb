# frozen_string_literal: true

module Lpms3
  # Baris master rekanan (lpms3.rekanan). Logika ada di Lpms3::Rekanan.
  class RekananRow < ::ApplicationRecord
    self.table_name = "lpms3.rekanan"

    has_many :evaluasi, class_name: "Lpms3::RekananEvaluasi", foreign_key: :rekanan_id

    def hitam? = status == "DAFTAR_HITAM"
  end
end
