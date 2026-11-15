# frozen_string_literal: true

module Lpms3
  # Riwayat kurs bersifat append-only (jejak audit): baris tidak dapat diubah atau dihapus setelah dibuat.
  class ExchangeRate < ::ApplicationRecord
    self.table_name = "lpms3_exchange_rates"
    SOURCES = %w[manual frankfurter].freeze

    belongs_to :currency, class_name: "Lpms3::Currency", foreign_key: :currency_code, primary_key: :code, inverse_of: :rates
    belongs_to :created_by, class_name: "User", optional: true

    validates :currency, presence: true
    validates :rate, numericality: { greater_than: 0, less_than: 1_000_000_000_000 }
    validates :valid_on, presence: true
    validates :source, inclusion: { in: SOURCES }
    validates :note, length: { maximum: 200 }
    validate { errors.add(:currency_code, :invalid) if currency&.is_base }

    before_update { throw :abort }
    before_destroy { throw :abort }
    def readonly? = !new_record?

    # Kurs berlaku pada tanggal tertentu: baris terbaru dengan valid_on <= tanggal (yang dibuat terakhir menang).
    def self.effective(code, on = Date.current)
      where(currency_code: code).where("valid_on <= ?", on).order(valid_on: :desc, created_at: :desc, id: :desc).first
    end
  end
end
