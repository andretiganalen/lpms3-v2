# frozen_string_literal: true

module Lpms3
  # Masukan dari pembaca (akses lihat saja) kepada pembuat dokumen: typo, salah ketik, atau perbaikan kecil.
  # Tidak mengubah status persetujuan dan tidak memicu reviu ulang.
  class Feedback < ::ApplicationRecord
    self.table_name = "lpms3_feedbacks"

    class Error < StandardError; end

    belongs_to :work_package
    belongs_to :project
    belongs_to :given_by, class_name: "User"
    belongs_to :author, class_name: "User"
    belongs_to :resolved_by, class_name: "User", optional: true

    scope :open, -> { where(state: "terbuka") }

    validates :body, presence: true
    validates :state, inclusion: { in: %w[terbuka diperbaiki] }

    class << self
      # Pembaca mana pun yang bisa melihat dokumen boleh memberi masukan, termasuk akses Baca Saja.
      def give!(work_package, user, body)
        text = body.to_s.strip
        raise Error, "Isi masukan wajib diisi." if text.empty?
        raise Error, "Dokumen ini tidak bisa dilihat oleh Anda." unless ::WorkPackage.visible(user).exists?(id: work_package.id)
        raise Error, "Pembuat dokumen tidak mengisi kolom penulis." if work_package.author_id.blank?

        transaction do
          fb = create!(work_package:, project: work_package.project, given_by: user, author_id: work_package.author_id,
                       body: text, given_at: Time.current)
          journal_note!(work_package, "Masukan dari #{user.name} untuk #{work_package.author&.name}:\n#{text}")
          fb
        end
      end

      # Catatan ke aktivitas WP (panel kanan / Activity): menjadi jejak bukti percakapan masukan.
      def journal_note!(work_package, note)
        work_package.journal_notes = note
        work_package.save!(validate: false)
      end

      # Masukan terbuka untuk pembuat dokumen, diurutkan dari yang paling lama.
      def open_for(user)
        open.where(author_id: user.id).includes(:work_package, :project, :given_by).order(:given_at)
      end
    end

    # Pembuat menandai masukan sudah diperbaiki. Status persetujuan dokumen tidak berubah.
    def resolve!(user, note = nil)
      raise Error, "Hanya pembuat dokumen yang bisa menandai masukan selesai." unless user.id == author_id
      raise Error, "Masukan ini sudah ditandai selesai." unless state == "terbuka"

      transaction do
        update!(state: "diperbaiki", resolved_by: user, resolved_at: Time.current, resolution_note: note.to_s.strip.presence)
        self.class.journal_note!(work_package, "Masukan selesai diperbaiki oleh #{user.name}" \
                                               "#{note.to_s.strip.present? ? ": #{note.to_s.strip}" : ''}")
      end
      self
    end
  end
end
