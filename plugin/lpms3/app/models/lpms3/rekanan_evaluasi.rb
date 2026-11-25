# frozen_string_literal: true

module Lpms3
  # Evaluasi penyedia (PFR-019) per Item Pengadaan: skor 1–5 mutu, waktu, harga, K3L.
  class RekananEvaluasi < ::ApplicationRecord
    self.table_name = "lpms3.rekanan_evaluasi"

    belongs_to :rekanan_row, class_name: "Lpms3::RekananRow", foreign_key: :rekanan_id
    belongs_to :evaluator, class_name: "::User"

    def rata = ((skor_mutu + skor_waktu + skor_harga + skor_k3l) / 4.0).round(2)
  end
end
