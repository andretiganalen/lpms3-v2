# frozen_string_literal: true

module Lpms3
  class Currency < ::ApplicationRecord
    self.table_name = "lpms3_currencies"
    has_many :rates, class_name: "Lpms3::ExchangeRate", foreign_key: :currency_code, primary_key: :code, inverse_of: :currency

    validates :code, presence: true, format: { with: /\A[A-Z]{3}\z/ }, uniqueness: true
    validates :name, presence: true, length: { maximum: 60 }
    validates :symbol, presence: true, length: { maximum: 6 }
    validates :minor_units, inclusion: { in: 0..4 }
    before_validation { self.code = code.to_s.strip.upcase }

    scope :ordered, -> { order(:position, :code) }
    scope :active, -> { where(active: true) }

    def self.base = find_by(is_base: true)
  end
end
