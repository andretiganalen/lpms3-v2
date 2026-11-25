# frozen_string_literal: true

module Lpms3
  # Panel header gaya LenO: penyegaran berkala Reminder, Tasklist, Notifikasi (LPMS::Lpms3::HeaderSummary).
  # Hanya data milik pengguna sendiri; tanpa parameter yang memilih pengguna lain.
  class HeaderController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :ringkasan, :baca_notifikasi

    def ringkasan
      render json: ::OpenProject::Lpms3::HeaderSummary.build(User.current)
    end

    def baca_notifikasi
      n = ::Notification.where(recipient_id: User.current.id, read_ian: false).update_all(read_ian: true, updated_at: Time.current)
      render json: { dibaca: n }
    end
  end
end
