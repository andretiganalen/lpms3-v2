# frozen_string_literal: true

module Lpms3
  # Kotak tugas terpadu (Tugas & Notifikasi): satu sumber untuk daftar dan jumlah di menu.
  module Inbox
    module_function

    def persetujuan(user) = ApprovalTask.pending_for(user)
    def tembusan(user) = ApprovalTask.tembusan_candidates(user)
    def kickoff(user) = Kickoff.pending_for(user)
    def masukan(user) = Feedback.open_for(user)
    def pemicu(user) = ProjectTrigger.pending_for(user)
    def wbs_pic(user) = Wbs.pic_pending_for(user)

    # Jumlah item yang menunggu tindakan user (dipakai badge menu).
    def count(user)
      return 0 unless user&.logged?

      persetujuan(user).size + tembusan(user).size + kickoff(user).size + masukan(user).size + pemicu(user).size +
        wbs_pic(user).size
    end
  end
end
