module Lpms3
  module Admin
    # Settings > Organisasi & Fungsi: struktur organisasi aktif dan pemetaan Fungsi Generik -> Unit Aktual (Nota 021).
    class OrganisasiController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      menu_item :lpms3_organisasi

      def index
        @structure = ::Lpms3::OrgStructure.active.first
        @query = params[:q].to_s.strip
        return unless @structure

        units = @structure.units.includes(mappings: %i[fungsi fungsi_lama]).order(:code).to_a
        @counts = units.group_by(&:grade).transform_values(&:size)
        @mapping_count = units.sum { |u| u.mappings.size }
        @tree = build_tree(units)
      end

      private

      # [{ dir:, divisions: [{ div:, bagian: [unit, ...] }] }], disaring oleh pencarian bila ada.
      def build_tree(units)
        by_parent = units.group_by(&:parent_id)
        (by_parent[nil] || []).filter_map do |dir|
          divisions = (by_parent[dir.id] || []).filter_map do |div|
            bagian = (by_parent[div.id] || []).select { |b| matches?(b) || matches?(div) || matches?(dir) }
            next unless matches?(div) || matches?(dir) || bagian.any?

            { div:, bagian: }
          end
          next if divisions.empty? && !matches?(dir)

          { dir:, divisions: }
        end
      end

      def matches?(unit)
        return true if @query.blank?

        needle = @query.downcase
        haystack = [unit.name, *unit.aliases, *unit.mappings.flat_map { |m| [m.fungsi.name, m.fungsi_lama&.name] }]
        haystack.compact.any? { |s| s.downcase.include?(needle) }
      end
    end
  end
end
