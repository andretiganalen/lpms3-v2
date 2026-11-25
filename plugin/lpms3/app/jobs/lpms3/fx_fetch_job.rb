# frozen_string_literal: true

module Lpms3
  # Ambil kurs harian bila sumber diaktifkan dan opsi otomatis menyala; selain itu tidak melakukan apa pun.
  class FxFetchJob < ::ApplicationJob
    def perform
      return unless OpenProject::Lpms3::Fx.source_enabled? && OpenProject::Lpms3::Fx.auto?

      res = OpenProject::Lpms3::Fx.fetch!
      Rails.logger.info "[LPMS3] Kurs otomatis: #{res.inspect}"
    end
  end
end
