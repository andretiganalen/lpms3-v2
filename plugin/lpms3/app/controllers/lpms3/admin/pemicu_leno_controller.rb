# frozen_string_literal: true

module Lpms3
  module Admin
    # Administrasi > Pemicu LenO: daftar pemicu proyek yang diterima dan riwayatnya (hanya baca, rilis 1.35).
    class PemicuLenoController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      menu_item :lpms3_pemicu_leno

      def index
        @status = params[:status].presence_in(::Lpms3::ProjectTrigger::STATUSES)
        scope = ::Lpms3::ProjectTrigger.includes(:project, events: :actor).order(kiriman_terakhir_pada: :desc)
        scope = scope.where(status: @status) if @status
        @triggers = scope.limit(200).to_a
        @counts = ::Lpms3::ProjectTrigger.group(:status).count
        @key_configured = ENV.fetch("LPMS3_LENO_KEYS", "").split(",").any? { |k| k.strip.length >= ::Lpms3::PemicuLenoController::MIN_KEY_LENGTH }
      end
    end
  end
end
