# frozen_string_literal: true

module Lpms3
  # Menu Mata Uang & Kurs. Semua pengguna login dapat melihat dan memakai konversi; mengubah mata uang/kurs hanya
  # untuk admin dan akun dengan izin global manage_currency_rates (peran Keuangan). Sumber eksternal hanya admin.
  class CurrenciesController < ::ApplicationController
    before_action :require_login
    before_action :require_finance, except: %i[index]
    before_action :require_admin_only, only: %i[update_source]
    no_authorization_required! :index, :create_currency, :update_currency, :create_rate, :fetch, :update_source, :apply_budget
    layout "global" # sidebar global seperti LenO

    def index
      @fx = ::OpenProject::Lpms3::Fx
      @can_edit = finance?
      @currencies = ::Lpms3::Currency.ordered.to_a
      @base = @currencies.find(&:is_base)
      @latest = @currencies.reject(&:is_base).to_h { |c| [c.code, ::Lpms3::ExchangeRate.effective(c.code)] }
      @history = ::Lpms3::ExchangeRate.includes(:created_by).order(created_at: :desc, id: :desc).limit(30).to_a
      load_conversion
      load_budgets
    end

    def create_currency
      c = ::Lpms3::Currency.new(params.permit(:code, :name, :symbol, :minor_units).merge(position: ::Lpms3::Currency.maximum(:position).to_i + 1))
      back(c.save ? { notice: t("lpms3.currencies.saved") } : { error: c.errors.full_messages.to_sentence })
    end

    def update_currency
      c = ::Lpms3::Currency.find(params[:id])
      attrs = params.permit(:name, :symbol, :minor_units, :active)
      attrs.delete(:active) if c.is_base # mata uang dasar selalu aktif
      back(c.update(attrs) ? { notice: t("lpms3.currencies.saved") } : { error: c.errors.full_messages.to_sentence })
    end

    def create_rate
      raw = params[:rate].to_s.strip.tr(",", ".")
      rate = ::Lpms3::ExchangeRate.new(currency_code: params[:currency_code].to_s.upcase, rate: (BigDecimal(raw) rescue nil), valid_on: (Date.iso8601(params[:valid_on].to_s) rescue nil),
                                       note: params[:note].to_s.strip.presence, source: "manual", created_by: User.current)
      back(rate.save ? { notice: t("lpms3.currencies.rate_saved") } : { error: rate.errors.full_messages.to_sentence.presence || t("lpms3.currencies.rate_invalid") })
    end

    def fetch
      return back(error: t("lpms3.currencies.source_off")) unless ::OpenProject::Lpms3::Fx.source_enabled?

      res = ::OpenProject::Lpms3::Fx.fetch!(user: User.current)
      msg = t("lpms3.currencies.fetched", ok: res[:fetched].size, skipped: res[:skipped].size, errors: res[:errors].size)
      back(res[:errors].any? ? { error: "#{msg} #{res[:errors].first}" } : { notice: msg })
    rescue StandardError => e
      back(error: "#{e.class}: #{e.message[0, 120]}")
    end

    def update_source
      src = params[:source].to_s
      src = "" unless ::OpenProject::Lpms3::Fx::SOURCES.key?(src)
      Setting.lpms3_fx_source = src
      Setting.lpms3_fx_auto = (src.present? && params[:auto] == "1") ? "1" : ""
      back(notice: t("lpms3.currencies.saved"))
    end

    def apply_budget
      ::OpenProject::Lpms3::Fx.apply_base_to_budget_settings!
      back(notice: t("lpms3.currencies.budget_applied", symbol: Setting.costs_currency))
    end

    private

    def finance? = User.current.admin? || User.current.allowed_globally?(:manage_currency_rates)

    def require_finance = (deny_access unless finance?)

    def require_admin_only = (deny_access unless User.current.admin?)

    def back(flash_args)
      flash_args.each { |k, v| flash[k] = v }
      redirect_to lpms3_currencies_index_path
    end

    def load_conversion
      codes = @currencies.map(&:code)
      @c_from = codes.include?(params[:from]) ? params[:from] : "USD"
      @c_to = codes.include?(params[:to]) ? params[:to] : (@base&.code || "IDR")
      @c_on = (Date.iso8601(params[:on].to_s) rescue Date.current)
      raw = params[:amount].to_s.strip.tr(",", ".")
      @c_amount = (BigDecimal(raw) rescue nil) if raw.present?
      return unless @c_amount

      conv = @fx.convert(@c_amount, @c_from, @c_to, @c_on)
      @c_result = conv && @fx.round_for(conv, @c_to)
      @c_missing = conv.nil?
    end

    # Budget project yang boleh dilihat pengguna, dalam mata uang budget (dasar) dan mata uang pilihan.
    def load_budgets
      @budget_rows = []
      return unless defined?(::Budget)

      projects = Project.allowed_to(User.current, :view_budgets).pluck(:id)
      ::Budget.where(project_id: projects).includes(:project).order(:project_id, :id).limit(200).each do |b|
        amount = b.budget.to_d
        shown = @fx.convert(amount, @base&.code, @c_to, @c_on)
        @budget_rows << [b, amount, shown && @fx.round_for(shown, @c_to)]
      end
    rescue StandardError => e
      Rails.logger.warn "[LPMS3] Daftar budget dilewati: #{e.class}: #{e.message}"
    end
  end
end
