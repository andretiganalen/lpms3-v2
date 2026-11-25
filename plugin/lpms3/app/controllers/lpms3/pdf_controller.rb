# frozen_string_literal: true

module Lpms3
  # Unduh PDF: tabel 9 Aspek PMP per proyek dan laporan harian per WO (gaya UIx).
  class PdfController < ::ApplicationController
    PDF = ::OpenProject::Lpms3::PDF
    AP = ::OpenProject::Lpms3::Aspects
    L = ::Lpms3::Leno

    before_action :find_project, only: :aspek
    before_action :find_wo, only: :laporan
    no_authorization_required! :aspek, :laporan

    def aspek
      return deny_access unless User.current.allowed_in_project?(:view_work_packages, @project)

      aspects = AP.scope(@project, User.current).includes(:status).order(:id).to_a
      pdf = PDF.document
      PDF.heading(pdf, title: "Penetapan 9 Aspek PMP", subtitle: @project.name,
                       meta: [["Dicetak", I18n.l(Time.zone.today, format: :long)], ["Jumlah aspek", aspects.size]])
      PDF.table(pdf, ["Aspek", "Status", "Isi"],
                aspects.map { |wp| [AP.name(wp), wp.status.name, ActionView::Base.full_sanitizer.sanitize(wp.description.to_s)] },
                widths: [150, 90, pdf.bounds.width - 240])
      PDF.footer(pdf, "Penetapan 9 Aspek PMP · #{@project.name}")
      send_data pdf.render, filename: "aspek-pmp-#{@project.identifier}.pdf", type: "application/pdf", disposition: "attachment"
    end

    def laporan
      reports = L.reports(@wp).sort_by(&:report_date)
      pdf = PDF.document
      PDF.heading(pdf, title: "Laporan Harian", subtitle: "#{L.code(@wp)} · #{L.title(@wp)}",
                       meta: [["Proyek", @wp.project.name], ["Progres terakhir", "#{L.progress(@wp).round}%"],
                              ["Dicetak", I18n.l(Time.zone.today, format: :long)]])
      PDF.table(pdf, ["Tanggal", "Progres", "Perubahan", "Pelaksanaan", "Keterangan", "Kendala"],
                reports.map do |r|
                  [I18n.l(r.report_date, format: "%d %b %Y"), "#{r.progress.to_f}%",
                   "#{format('%+.1f', r.progress.to_f - r.prev_progress.to_f)}%",
                   r.execution == "kendala" ? "Ada kendala" : "Sesuai rencana",
                   r.keterangan.to_s, r.kendala.to_s]
                end,
                widths: [70, 50, 55, 80, pdf.bounds.width - 375, 120])
      PDF.footer(pdf, "Laporan Harian #{L.code(@wp)}")
      send_data pdf.render, filename: "laporan-harian-#{L.code(@wp).to_s.parameterize}.pdf", type: "application/pdf", disposition: "attachment"
    end

    private

    def find_project
      @project = ::Project.find_by(identifier: params[:project_id]) || ::Project.find_by(id: params[:project_id])
      render_404 unless @project
    end

    def find_wo
      @wp = ::WorkPackage.visible(User.current).find_by(id: params[:id])
      render_404 unless @wp && L.code(@wp)
    end
  end
end
