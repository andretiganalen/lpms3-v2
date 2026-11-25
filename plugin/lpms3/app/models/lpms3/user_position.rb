module Lpms3
  # Penugasan pengguna ke jabatan (DEFINITIF/PLT/PLH/DELEGASI) dengan masa berlaku. Riwayat tidak dihapus:
  # mengakhiri jabatan = mengisi valid_to.
  class UserPosition < ::ApplicationRecord
    self.table_name = "lpms3.user_position"
    TYPES = %w[DEFINITIF PLT PLH DELEGASI].freeze

    belongs_to :position, class_name: "Lpms3::Position", inverse_of: :user_positions
    belongs_to :user, class_name: "::User"

    validates :assignment_type, inclusion: { in: TYPES }
    validates :valid_from, presence: true
    validate :range_valid

    scope :active_on, ->(date = Date.current) {
      where(valid_from: ..date).where("valid_to IS NULL OR valid_to >= ?", date)
    }

    def active?(date = Date.current) = valid_from <= date && (valid_to.nil? || valid_to >= date)

    def end!(date = Date.current - 1)
      update!(valid_to: [date, valid_from].max, updated_at: Time.current)
    end

    private

    def range_valid
      errors.add(:valid_to, "tidak boleh sebelum tanggal mulai") if valid_to && valid_from && valid_to < valid_from
    end
  end
end
