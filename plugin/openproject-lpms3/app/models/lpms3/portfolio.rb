# frozen_string_literal: true

module Lpms3
  # Scorecard portofolio: satu baris per proyek yang bisa dilihat pengguna.
  #
  # Sumber dan batasan (dicatat agar angka bisa diaudit):
  #  - Rencana % : rata-rata persentase waktu berjalan tiap WP (Task/Deliverable/Feature) terhadap jadwalnya.
  #                Kurva-S (ffr708_kurva_s) belum terisi, sehingga rencana diturunkan dari jadwal WP.
  #  - Aktual %  : rata-rata done_ratio WP yang sama.
  #  - Leading/Lagging: Leading bila aktual >= rencana, selain itu Lagging.
  #  - Kenaikan  : selisih aktual sekarang dan aktual pada awal periode, memakai riwayat jurnal WP
  #                (hanya WP yang nilainya diketahui pada kedua waktu).
  #  - Judul    : field "Judul Proyek Lengkap" (jika kosong, nama proyek).
  #  - Isu / Risiko: WP tipe "Isu" / "Risiko" yang statusnya belum tertutup.
  module Portfolio
    PERIODS = %w[day week month quarter].freeze
    EXECUTION_TYPES = %w[Task Deliverable Feature].freeze

    module_function

    def projects(user)
      ::Project.active.visible(user).order(:name)
    end

    def rows(user, period: "month", today: Time.zone.today)
      period = "month" unless PERIODS.include?(period)
      prev = previous_date(period, today)
      # Diurutkan berdasarkan Kode Proyek (proyek tanpa kode di bawah).
      projects(user).map do |project|
        photos = ::Lpms3::Gallery.photos(project, user, today:)
        row(project, today, prev).merge(galeri: photos.first(4), galeri_total: photos.size)
      end
                    .sort_by { |r| [r[:kode].present? ? 0 : 1, r[:kode].to_s, r[:judul].to_s] }
    end

    def previous_date(period, today)
      case period
      when "day" then today - 1
      when "week" then today - 7
      when "quarter" then today.prev_month(3)
      else today.prev_month(1)
      end
    end

    def row(project, today, prev)
      wps = ::WorkPackage.where(project_id: project.id, type: ::Type.where(name: EXECUTION_TYPES))
                         .where.not(start_date: nil).where.not(due_date: nil).to_a
      planned = avg(wps.map { |wp| planned_pct(wp, today) })
      actual = avg(wps.map(&:done_ratio))

      # kenaikan: hanya WP yang nilainya diketahui di awal periode dan sekarang
      pairs = wps.filter_map do |wp|
        was = done_ratio_at(wp, prev)
        [wp.done_ratio.to_f, was.to_f] unless was.nil?
      end
      delta = pairs.any? ? (avg(pairs.map(&:first)) - avg(pairs.map(&:last))) : nil

      deadline = date_of(cfv(project, "Tanggal Selesai Kontrak")) || wps.map(&:due_date).max
      start = date_of(cfv(project, "Tanggal Kick-Off (Baseline 0)")) || date_of(cfv(project, "Tanggal Kontrak")) ||
              wps.map(&:start_date).min

      {
        id: project.id,
        kode: cfv(project, "Kode Proyek").presence || project.identifier,
        judul: cfv(project, "Judul Proyek Lengkap").presence || project.name,
        kontrak: cfv(project, "Nomor Kontrak"),
        amendemen: cfv(project, "Nomor Adendum Terakhir"),
        rencana: planned&.round(1),
        aktual: actual&.round(1),
        status: status(planned, actual),
        isu: open_count(project, "Isu"),
        risiko: open_count(project, "Risiko"),
        sisa_hari: deadline && (deadline - today).to_i,
        jalan_hari: start && (today - start).to_i,
        jalan_pct: (start && deadline && deadline > start) ? (((today - start).to_f / (deadline - start)) * 100).clamp(0, 100).round(1) : nil,
        kenaikan: delta&.round(1),
        jumlah_wp: wps.size
      }
    end

    def planned_pct(wp, today)
      s = wp.start_date
      e = wp.due_date
      return (today >= e ? 100.0 : 0.0) if e <= s

      ((today - s).to_f / (e - s).to_f * 100).clamp(0, 100)
    end

    # done_ratio WP sebagai pada tanggal tertentu, dari riwayat jurnal; nil bila tidak diketahui.
    def done_ratio_at(wp, date)
      row = ::WorkPackage.connection.select_one(<<~SQL.squish)
        SELECT wpj.done_ratio FROM work_package_journals wpj
        JOIN journals j ON j.id = wpj.id
        WHERE j.journable_type = 'WorkPackage' AND j.journable_id = #{wp.id.to_i}
          AND j.created_at < #{::WorkPackage.connection.quote((date + 1).to_time(:local))}
        ORDER BY j.created_at DESC LIMIT 1
      SQL
      row && row["done_ratio"].to_f
    end

    def status(planned, actual)
      return "—" if planned.nil? || actual.nil?

      actual >= planned ? "Leading" : "Lagging"
    end

    def open_count(project, type_name)
      type = ::Type.find_by(name: type_name)
      return 0 unless type

      ::WorkPackage.joins(:status).where(project_id: project.id, type_id: type.id, statuses: { is_closed: false }).count
    end

    def cfv(project, name)
      cf = ::ProjectCustomField.find_by(name:)
      return nil unless cf

      project.custom_values.find { |cv| cv.custom_field_id == cf.id }&.value.presence
    end

    def date_of(str) = (Date.iso8601(str.to_s) rescue nil)

    def avg(list)
      vals = list.compact
      vals.empty? ? nil : vals.sum.to_f / vals.size
    end
  end
end
