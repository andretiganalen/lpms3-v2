# frozen_string_literal: true

require "csv"

module Lpms3
  module Admin
    # Administrasi > Jabatan Pengguna (1.39): siapa Kepala/Admin/Staf setiap unit Direksi/ES1/ES2. Sumber hierarki
    # untuk member proyek berjenjang (Lpms3::TimProyek). Riwayat tidak dihapus: mengakhiri jabatan mengisi valid_to.
    class JabatanController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      menu_item :lpms3_jabatan

      CSV_HEADERS = %w[email kode_unit jabatan jenis mulai sampai].freeze
      MAX_CSV_BYTES = 512 * 1024

      def index
        @structure = ::Lpms3::OrgStructure.active.first
        @query = params[:q].to_s.strip
        @users = ::User.active.where(type: "User").order(:firstname, :lastname).to_a
        @projects = ::Project.where(templated: false, active: true).order(:name).to_a
        return unless @structure

        units = @structure.units.where(grade: %w[DIREKSI ES1 ES2]).includes(positions: { user_positions: :user }).order(:code).to_a
        units = units.select { |u| match?(u) } if @query.present?
        @units = units
        @all_units = @structure.units.where(grade: %w[DIREKSI ES1 ES2]).order(:code).to_a
        @filled = ::Lpms3::UserPosition.active_on.where(position_id: ::Lpms3::Position.where(is_head: true).select(:id)).distinct.count(:position_id)
        @heads = ::Lpms3::Position.where(is_head: true).count
        @default_team = default_team_preview
      end

      def create
        unit = ::Lpms3::OrgUnit.find_by(id: params[:unit_id])
        user = ::User.active.find_by(id: params[:user_id])
        if unit.nil? || user.nil?
          flash[:error] = "Unit atau pengguna tidak ditemukan."
        else
          begin
            assign!(unit:, user:, kind: params[:jabatan].to_s, type: params[:jenis].to_s,
                    from: parse_date(params[:mulai]) || Date.current, to: parse_date(params[:sampai]))
            flash[:notice] = "#{user.name} ditetapkan sebagai #{params[:jabatan].to_s.capitalize} #{unit.name}."
          rescue ActiveRecord::RecordInvalid, ArgumentError, Date::Error => e
            flash[:error] = "Gagal menetapkan jabatan: #{e.message}"
          end
        end
        redirect_to lpms3_admin_jabatan_path(q: params[:q].presence)
      end

      def akhiri
        up = ::Lpms3::UserPosition.find(params[:id])
        up.end!
        flash[:notice] = "Jabatan #{up.position.title} untuk #{up.user&.name} diakhiri per #{I18n.l(up.valid_to)}."
        redirect_to lpms3_admin_jabatan_path(q: params[:q].presence)
      end

      # Impor CSV: email,kode_unit,jabatan(KEPALA|ADMIN|STAF),jenis(DEFINITIF|PLT|PLH|DELEGASI),mulai,sampai.
      # Baris bermasalah dilewati dan dilaporkan; baris yang sudah sama persis tidak digandakan.
      def impor
        file = params[:berkas]
        return redirect_with_error("Pilih berkas CSV terlebih dahulu.") unless file.respond_to?(:read)
        return redirect_with_error("Berkas terlalu besar (maks. 512 KB).") if file.size > MAX_CSV_BYTES

        st = ::Lpms3::OrgStructure.active.first
        return redirect_with_error("Belum ada struktur organisasi aktif.") unless st

        ok = 0
        errors = []
        rows = CSV.parse(file.read.force_encoding("UTF-8").delete_prefix("﻿"), headers: true,
                                                                                   header_converters: ->(h) { h.to_s.strip.downcase })
        missing = CSV_HEADERS.first(3) - rows.headers.compact
        return redirect_with_error("Kolom wajib tidak ada: #{missing.join(', ')}.") if missing.any?

        rows.each.with_index(2) do |row, line|
          email = row["email"].to_s.strip.downcase
          user = ::User.active.where("LOWER(mail) = ? OR LOWER(login) = ?", email, email).first
          unit = st.units.find_by(code: row["kode_unit"].to_s.strip)
          next errors << "baris #{line}: pengguna #{email.presence || '(kosong)'} tidak ditemukan/aktif" unless user
          next errors << "baris #{line}: kode unit #{row['kode_unit']} tidak ada" unless unit

          assign!(unit:, user:, kind: row["jabatan"].to_s.strip.upcase, type: (row["jenis"].presence || "DEFINITIF").strip.upcase,
                  from: parse_date(row["mulai"]) || Date.current, to: parse_date(row["sampai"]))
          ok += 1
        rescue ActiveRecord::RecordInvalid, ArgumentError, Date::Error => e
          errors << "baris #{line}: #{e.message}"
        end
        flash[:notice] = "Impor selesai: #{ok} baris diterapkan#{", #{errors.size} dilewati" if errors.any?}."
        flash[:error] = errors.first(15).join("; ") + (errors.size > 15 ? "; …" : "") if errors.any?
        redirect_to lpms3_admin_jabatan_path
      rescue CSV::MalformedCSVError => e
        redirect_with_error("CSV tidak valid: #{e.message}")
      end

      # Terapkan tim default + atasan Eselon 2 Pimpro ke satu proyek atau semua proyek aktif.
      def sinkron
        projects = if params[:project_id] == "semua"
                     ::Project.where(templated: false, active: true).to_a
                   else
                     [::Project.find(params.require(:project_id))]
                   end
        added = []
        warnings = []
        projects.each do |p|
          r = ::Lpms3::TimProyek.sync!(p)
          added += r.added.map { |u, role, _| "#{u.name} (#{role}) di #{p.name}" }
          warnings += r.warnings
        end
        flash[:notice] = added.any? ? "Ditambahkan #{added.size} member: #{added.first(10).join('; ')}#{' …' if added.size > 10}" : "Tim proyek sudah lengkap; tidak ada member baru."
        flash[:warning] = warnings.uniq.first(8).join(" ") if warnings.any?
        redirect_to lpms3_admin_jabatan_path
      end

      private

      def assign!(unit:, user:, kind:, type:, from:, to:)
        raise ArgumentError, "jabatan harus KEPALA, ADMIN, atau STAF" unless ::Lpms3::Position::KIND.include?(kind)
        raise ArgumentError, "jenis harus #{::Lpms3::UserPosition::TYPES.join('/')}" unless ::Lpms3::UserPosition::TYPES.include?(type)

        pos = ::Lpms3::Position.ensure_for!(unit, kind)
        existing = ::Lpms3::UserPosition.active_on(from).find_by(position_id: pos.id, user_id: user.id, assignment_type: type)
        return existing if existing

        # Kepala DEFINITIF hanya satu: kepala definitif sebelumnya diakhiri sehari sebelum yang baru mulai.
        if kind == "KEPALA" && type == "DEFINITIF"
          ::Lpms3::UserPosition.active_on(from).where(position_id: pos.id, assignment_type: "DEFINITIF")
                               .where.not(user_id: user.id).find_each { |up| up.end!(from - 1) }
        end
        ::Lpms3::UserPosition.create!(position: pos, user:, assignment_type: type, valid_from: from, valid_to: to,
                                      basis_doc: "Administrasi LPMS3 oleh #{User.current.login}", updated_at: Time.current)
      end

      def parse_date(value)
        value.present? ? Date.parse(value.to_s.strip) : nil
      end

      def match?(unit)
        needle = @query.downcase
        [unit.name, unit.code, *unit.aliases,
         *unit.positions.flat_map { |p| p.user_positions.map { |up| up.user&.name } }].compact.any? { |s| s.downcase.include?(needle) }
      end

      def redirect_with_error(msg)
        flash[:error] = msg
        redirect_to lpms3_admin_jabatan_path
      end

      def default_team_preview
        es1 = ::Lpms3::Hierarki.unit_eselon1_of_fungsi
        dir = es1&.ancestor_with_grade("DIREKSI")
        [[dir, "KEPALA", "Direktur"], [dir, "ADMIN", "Admin Direktur"], [es1, "KEPALA", "Pejabat Eselon 1"],
         [es1, "ADMIN", "Admin Pejabat Eselon 1"]].map do |unit, kind, label|
          { label:, unit:, users: unit ? ::Lpms3::Hierarki.holders(unit, kind) : [] }
        end
      end
    end
  end
end
