# frozen_string_literal: true

module Lpms3
  # Halaman Portofolio LPMS3: scorecard satu baris per proyek, periode Day / Week / Month / Quarter.
  class PortfolioController < ::ApplicationController
    before_action :require_login
    no_authorization_required! :show

    def show
      @periode = ::Lpms3::Portfolio::PERIODS.include?(params[:periode]) ? params[:periode] : "month"
      @rows = ::Lpms3::Portfolio.rows(User.current, period: @periode)
      @prev = ::Lpms3::Portfolio.previous_date(@periode, Time.zone.today)
      @today = Time.zone.today
    end
  end
end
