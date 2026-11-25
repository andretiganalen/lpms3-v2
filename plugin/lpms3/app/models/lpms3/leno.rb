# frozen_string_literal: true

module Lpms3
  # LenO Mobile (mock-up "LenO Mobile – LPMS-3"): alur laporan harian WO oleh PIC dan persetujuan Pejabat Eselon 2.
  # Aturan:
  # - PIC (penanggung jawab WO) mengisi laporan harian; laporan hari sebelumnya harus sudah terkirim.
  # - Progres turun wajib disertai keterangan; kendala wajib diisi bila pelaksanaan "Ada kendala".
  # - Submit WO hanya saat progres 100 %. Setelah diajukan, WO menunggu Pejabat Eselon 2.
  # - Eselon 2 menyetujui (terkunci) atau menolak dengan alasan (kembali ke PIC untuk diperbaiki).
  module Leno
    class Error < StandardError; end
    CODE_RE = /\[(WO-\d+)\]/

    HARI_PANJANG = %w[Minggu Senin Selasa Rabu Kamis Jumat Sabtu].freeze
    HARI_SINGKAT = %w[Min Sen Sel Rab Kam Jum Sab].freeze
    BULAN_SINGKAT = %w[Jan Feb Mar Apr Mei Jun Jul Agu Sep Okt Nov Des].freeze
    BULAN_PANJANG = %w[Januari Februari Maret April Mei Juni Juli Agustus September Oktober November Desember].freeze

    # Format tanggal bahasa Indonesia: %A %a %d %e %b %B %Y (mis. "Senin, 16 Nov 2026").
    def fmt(date, pattern)
      return "" unless date

      pattern.gsub(/%([AadebBY])/) do
        case Regexp.last_match(1)
        when "A" then HARI_PANJANG[date.wday]
        when "a" then HARI_SINGKAT[date.wday]
        when "d" then format("%02d", date.day)
        when "e" then date.day.to_s
        when "b" then BULAN_SINGKAT[date.month - 1]
        when "B" then BULAN_PANJANG[date.month - 1]
        when "Y" then date.year.to_s
        end
      end
    end

    # Persentase untuk tampilan: bulat tanpa desimal, desimal dengan koma (72,5).
    def pct(value)
      v = value.to_f
      (v % 1).zero? ? v.to_i.to_s : format("%.1f", v).tr(".", ",")
    end
    module_function :fmt, :pct

    module_function

    def wos_of_pic(user)
      ::WorkPackage.joins(:type).where(assigned_to_id: user.id, types: { name: "Task" })
                   .where("work_packages.subject LIKE ?", "[WO-%").order(:id).to_a
    end

    def code(wp) = wp.subject[CODE_RE, 1]
    def title(wp) = wp.subject.sub(/\A\[WO-\d+\]\s*/, "")
    def review(wp) = WoReview.for(wp)
    def reports(wp) = DailyReport.where(work_package_id: wp.id).order(:report_date).to_a
    def today = Date.current

    def approver?(user, project) = ::OpenProject::Lpms3::Aspects.approver?(user, project)

    def approver_any?(user)
      ::Member.where(user_id: user.id).joins(:roles).where(roles: { name: ::OpenProject::Lpms3::Aspects::APPROVER_ROLES }).exists? || user.admin?
    end

    # Progres saat ini: dari laporan terkirim terakhir, atau persentase WP bila belum ada laporan.
    def progress(wp)
      last = DailyReport.where(work_package_id: wp.id, status: "terkirim").order(:report_date).last
      last ? last.progress.to_f : wp.done_ratio.to_f
    end

    def previous_report(wp, date)
      DailyReport.where(work_package_id: wp.id).where("report_date < ?", date).order(:report_date).last
    end

    def pic!(wp, user)
      raise Error, "Hanya PIC WO ini yang dapat mengisi laporan." unless wp.assigned_to_id == user.id
    end

    def editable!(wp)
      r = review(wp)
      raise Error, "WO sudah disetujui dan terkunci." if r.locked?
      raise Error, "WO sedang menunggu keputusan Pejabat Eselon 2." unless r.editable?
    end

    def simpan_draft!(wp, date, user, attrs)
      pic!(wp, user)
      editable!(wp)
      report = DailyReport.find_or_initialize_by(work_package_id: wp.id, report_date: date)
      raise Error, "Laporan tanggal #{fmt(date, "%d %b")} sudah terkirim." if report.sent?

      prev = previous_report(wp, date)
      raise Error, "Kirim laporan #{fmt(prev.report_date, "%d %b")} dulu, baru laporan hari ini bisa diisi." if prev && !prev.sent?

      report.assign_attributes(
        progress: attrs[:progress], execution: attrs[:execution].presence || "sesuai",
        keterangan: attrs[:keterangan].to_s.strip.presence, kendala: attrs[:kendala].to_s.strip.presence,
        prev_progress: prev ? prev.progress : 0, author_id: user.id, status: "draft"
      )
      report.photo_ids = (Array(report.photo_ids) + Array(attrs[:photo_ids])).uniq
      report.save!
      report
    end

    def kirim!(wp, date, user, attrs)
      report = simpan_draft!(wp, date, user, attrs)
      if report.progress < report.prev_progress && report.keterangan.blank?
        raise Error, "Progres turun: jelaskan penyebabnya di Keterangan."
      end
      raise Error, "Kendala wajib diisi bila pelaksanaan ada kendala." if report.execution == "kendala" && report.kendala.blank?

      report.update!(status: "terkirim", sent_at: Time.current)
      sync_done_ratio!(wp, user, report.progress)
      report
    end

    def sync_done_ratio!(wp, user, progress)
      result = ::WorkPackages::UpdateService.new(user:, model: wp).call(done_ratio: progress.round)
      raise Error, result.errors.full_messages.to_sentence unless result.success?
    end

    def submit!(wp, user)
      pic!(wp, user)
      r = review(wp)
      raise Error, "WO tidak dapat diajukan saat ini." unless r.editable?
      raise Error, "Submit WO aktif saat progres 100 %." if progress(wp) < 100

      r.update!(state: "diajukan", submitted_at: Time.current, reject_reason: nil)
      r
    end

    def decide!(wp, approver, action, reason = nil)
      r = review(wp)
      raise Error, "WO tidak sedang menunggu keputusan." unless r.state == "diajukan"
      raise Error, "Anda tidak berwenang memutuskan WO ini." unless approver?(approver, wp.project)

      if action == "approve"
        r.update!(state: "disetujui", decided_at: Time.current, decided_by_id: approver.id)
      else
        raise Error, "Alasan reject wajib diisi." if reason.to_s.strip.empty?

        r.update!(state: "ditolak", decided_at: Time.current, decided_by_id: approver.id, reject_reason: reason.to_s.strip)
      end
      r
    end

    def buat_kendala!(wp, user, category, level, description)
      pic!(wp, user)
      raise Error, "Deskripsi kendala wajib diisi." if description.to_s.strip.empty?

      result = ::WorkPackages::CreateService.new(user:).call(
        project: wp.project, type: ::Type.find_by!(name: "Isu"),
        subject: "[KENDALA #{code(wp)}] #{category}",
        description: "Dampak ke jadwal: #{level}.\n\n#{description.strip}"
      )
      raise Error, result.errors.full_messages.to_sentence unless result.success?

      result.result
    end

    # Daftar notifikasi dalam aplikasi, diturunkan dari data (tanpa pengiriman email).
    def notifikasi(user)
      items = []
      wos_of_pic(user).each do |wp|
        r = review(wp)
        if r.state == "ditolak"
          items << { tone: :danger, title: "#{code(wp)} di-reject Eselon 2", detail: r.reject_reason.to_s }
        elsif r.state == "disetujui"
          items << { tone: :ok, title: "#{code(wp)} di-approve · terkunci", detail: title(wp) }
        end
        unsent = reports(wp).reverse.find { |x| !x.sent? && x.report_date < today }
        if unsent
          items << { tone: :warn, title: "Laporan #{fmt(unsent.report_date, "%d %b")} belum dikirim",
                     detail: "#{title(wp)} · kirim dulu agar laporan hari ini terbuka" }
        end
        next unless wp.due_date && r.state != "disetujui"

        days = (wp.due_date - today).to_i
        if days == 7
          items << { tone: :info, title: "Tenggat 7 hari lagi", detail: "#{title(wp)} · #{fmt(wp.due_date, "%d %b")} · progres #{progress(wp).round}%" }
        elsif days.negative?
          items << { tone: :danger, title: "Lewat tenggat (H+#{-days})", detail: "#{title(wp)} · tenggat #{fmt(wp.due_date, "%d %b")}" }
        end
      end
      items
    end

    # WO yang menunggu keputusan user (Pejabat Eselon 2) dan riwayat keputusannya.
    def menunggu_keputusan(user)
      WoReview.where(state: "diajukan").includes(:work_package).order(:submitted_at).select do |r|
        approver?(user, r.work_package.project)
      end
    end

    def riwayat_keputusan(user)
      WoReview.where(decided_by_id: user.id).where.not(state: %w[berjalan diajukan]).includes(:work_package).order(decided_at: :desc).to_a
    end
  end
end
