# frozen_string_literal: true

module Lpms3
  # Panduan internal (tujuan tombol bantuan "?"): isi mengikuti bahasa akun yang sedang login (atau bahasa bawaan
  # untuk tamu). Hanya teks panduan yang diterjemahkan; data milik pengguna tidak ditampilkan di sini.
  class GuideController < ::ApplicationController
    no_authorization_required! :show
    skip_before_action :check_if_login_required
    layout "base"

    def show; end
  end
end
