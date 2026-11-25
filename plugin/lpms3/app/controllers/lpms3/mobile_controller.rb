# frozen_string_literal: true

module Lpms3
  # LenO Mobile: layar sesuai mock-up "LenO Mobile – LPMS-3" untuk PIC (Aktivitas, Laporan, Kendala, Notifikasi)
  # dan Pejabat Eselon 2 (Persetujuan, Keputusan, Tolak).
  class MobileController < ::ApplicationController
    L = ::Lpms3::Leno
    layout "lpms3_mobile"
    before_action :require_login
    before_action :load_wo, only: %i[aktivitas laporan simpan submit_wo kendala buat_kendala keputusan tolak tolak_simpan setujui]
    no_authorization_required! :index, :aktivitas, :laporan, :simpan, :submit_wo, :kendala, :buat_kendala,
                               :notifikasi, :persetujuan, :keputusan, :tolak, :tolak_simpan, :setujui
    rescue_from ::Lpms3::Leno::Error, with: :gagal
    rescue_from ActiveRecord::StaleObjectError, with: :konflik

    def index
      @filter = params[:f].presence || "semua"
      @cards = L.wos_of_pic(User.current).map { |wp| card(wp) }
      @cards = @cards.select { |c| filter_match?(c) }
      @title = "Aktivitas Saya"
    end

    def aktivitas
      @title = "Laporan Aktivitas"
      @review = L.review(@wp)
      @reports = L.reports(@wp).reverse
      @progress = L.progress(@wp)
      @pic = @wp.assigned_to_id == User.current.id
    end

    def laporan
      @title = "Laporan Harian"
      @date = date_param
      @report = DailyReport.find_by(work_package_id: @wp.id, report_date: @date) || DailyReport.new(progress: L.progress(@wp))
      @prev = L.previous_report(@wp, @date)
      @review = L.review(@wp)
      @progress = L.progress(@wp)
    end

    def simpan
      date = date_param
      attrs = report_params.merge(photo_ids: store_photos)
      if params[:mode] == "kirim"
        L.kirim!(@wp, date, User.current, attrs)
        L.submit!(@wp, User.current) if params[:submit_wo] == "1"
        flash[:notice] = params[:submit_wo] == "1" ? "Laporan terkirim dan WO diajukan ke Eselon 2." : "Laporan terkirim."
      else
        L.simpan_draft!(@wp, date, User.current, attrs)
        flash[:notice] = "Draft disimpan."
      end
      redirect_to lpms3_m_wo_path(@wp)
    end

    def submit_wo
      L.submit!(@wp, User.current)
      flash[:notice] = "WO diajukan ke Pejabat Eselon 2."
      redirect_to lpms3_m_wo_path(@wp)
    end

    def kendala
      @title = "Lapor Kendala"
    end

    def buat_kendala
      issue = L.buat_kendala!(@wp, User.current, params[:kategori].presence || "Lainnya",
                              params[:dampak].presence || "Sedang", params[:deskripsi])
      flash[:notice] = "Kendala dicatat sebagai Issue Log (#{issue.subject})."
      redirect_to lpms3_m_wo_path(@wp)
    end

    def notifikasi
      @title = "Notifikasi"
      @items = L.notifikasi(User.current)
    end

    def persetujuan
      @title = "Persetujuan"
      @tab = params[:tab] == "riwayat" ? "riwayat" : "menunggu"
      @waiting = L.menunggu_keputusan(User.current)
      @history = L.riwayat_keputusan(User.current)
      @proyek_options = (@waiting + @history).map { |r| r.work_package.project }.uniq(&:id).sort_by(&:name)
      @proyek = params[:proyek].presence
      return if @proyek.blank?

      @waiting = @waiting.select { |r| r.work_package.project_id.to_s == @proyek }
      @history = @history.select { |r| r.work_package.project_id.to_s == @proyek }
    end

    def keputusan
      @title = "Review Submission"
      deny_access unless L.approver?(User.current, @wp.project)
      @review = L.review(@wp)
      @reports = L.reports(@wp).reverse
      @progress = L.progress(@wp)
    end

    def tolak
      @title = "Alasan Reject"
      deny_access unless L.approver?(User.current, @wp.project)
    end

    def tolak_simpan
      L.decide!(@wp, User.current, "reject", params[:alasan])
      flash[:notice] = "Submission ditolak dan dikembalikan ke PIC."
      redirect_to lpms3_m_persetujuan_path
    end

    def setujui
      L.decide!(@wp, User.current, "approve")
      flash[:notice] = "WO disetujui dan terkunci."
      redirect_to lpms3_m_persetujuan_path
    end

    private

    Card = Struct.new(:wp, :code, :title, :state, :progress, :due, :draft, :late, keyword_init: true)

    def card(wp)
      r = L.review(wp)
      Card.new(wp:, code: L.code(wp), title: L.title(wp), state: r.state, progress: L.progress(wp).round,
               due: wp.due_date, draft: L.reports(wp).any? { |x| !x.sent? }, late: wp.due_date && wp.due_date < L.today && r.state != "disetujui")
    end

    def filter_match?(card)
      case @filter
      when "berjalan" then card.state == "berjalan"
      when "draft" then card.draft
      when "perbaikan" then card.state == "ditolak"
      else true
      end
    end

    def load_wo
      @wp = ::WorkPackage.find(params[:id])
      render_404 unless L.code(@wp)
      deny_access unless User.current.allowed_in_project?(:view_work_packages, @wp.project)
    end

    def date_param
      params[:tanggal].present? ? Date.parse(params[:tanggal]) : L.today
    rescue ArgumentError
      L.today
    end

    def report_params
      params.permit(:progress, :execution, :keterangan, :kendala).to_h.symbolize_keys
    end

    # Foto disimpan sebagai lampiran WO; id-nya dicatat pada laporan harian.
    def store_photos
      files = Array(params[:foto]).select { |f| f.respond_to?(:original_filename) }
      files.map do |f|
        result = ::Attachments::CreateService.new(user: User.current).call(container: @wp, file: f, filename: f.original_filename)
        raise ::Lpms3::Leno::Error, "Foto #{f.original_filename} gagal diunggah." unless result.success?

        result.result.id
      end
    end

    def gagal(error)
      flash[:error] = error.message
      redirect_back fallback_location: lpms3_m_path
    end

    def konflik(_error)
      flash[:error] = "Data sudah berubah. Muat ulang halaman lalu coba lagi."
      redirect_back fallback_location: lpms3_m_path
    end
  end
end
