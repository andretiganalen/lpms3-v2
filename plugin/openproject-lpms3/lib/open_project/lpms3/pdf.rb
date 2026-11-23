# frozen_string_literal: true

require "prawn"
require "prawn/table"

# LPMS3: cetak PDF dengan gaya UIx (kop judul, warna primer, tabel bergaris tipis).
# Warna dan ukuran diambil dari token UIx di assets/uix/uix.css agar cetakan sejalan dengan layar.
module OpenProject::Lpms3
  module PDF
    COLOR = {
      primary: "AE2524",    # --uix-primary
      head: "101828",       # --uix-text-head
      body: "344054",       # --uix-text-body
      muted: "667085",      # --uix-text-secondary
      border: "EAECF0",     # --uix-border-subtle
      head_bg: "F9FAFB"     # --uix-surface-subtle
    }.freeze
    SIZE = { page: 20, section: 18, card: 16, body: 10, small: 8 }.freeze

    module_function

    def document(orientation: :portrait)
      Prawn::Document.new(page_size: "A4", page_layout: orientation, margin: [48, 40, 56, 40]).tap do |pdf|
        pdf.font_families.update("Body" => { normal: "Helvetica" })
        pdf.font "Helvetica"
      end
    end

    # Kop: batang primer, judul, sub-judul, dan baris metadata (proyek, tanggal cetak, dsb).
    def heading(pdf, title:, subtitle: nil, meta: [])
      pdf.fill_color COLOR[:primary]
      pdf.fill_rectangle [0, pdf.bounds.top], pdf.bounds.width, 4
      pdf.move_down 12
      pdf.fill_color COLOR[:head]
      pdf.text title, size: SIZE[:section], style: :bold
      if subtitle.present?
        pdf.fill_color COLOR[:muted]
        pdf.text subtitle, size: SIZE[:body]
      end
      meta.each do |k, v|
        pdf.fill_color COLOR[:body]
        pdf.text "#{k}: #{v}", size: SIZE[:body]
      end
      pdf.move_down 12
      pdf.stroke_color COLOR[:border]
      pdf.stroke_horizontal_rule
      pdf.move_down 12
    end

    # Tabel bergaris tipis dengan header abu-abu seperti .lpms3-table di UIx.
    def table(pdf, headers, rows, widths: nil)
      data = [headers] + rows.map { |r| r.map { |c| c.to_s } }
      pdf.table(data, header: true, width: pdf.bounds.width, column_widths: widths) do |t|
        t.cells.size = SIZE[:body]
        t.cells.padding = [6, 8]
        t.cells.border_color = COLOR[:border]
        t.cells.text_color = COLOR[:body]
        t.row(0).font_style = :bold
        t.row(0).text_color = COLOR[:muted]
        t.row(0).background_color = COLOR[:head_bg]
        t.cells.overflow = :shrink_to_fit
      end
    end

    # Nomor halaman di kaki, dengan warna muted.
    def footer(pdf, label)
      pdf.fill_color COLOR[:muted]
      pdf.number_pages "#{label}  ·  halaman <page> dari <total>",
                       at: [0, -20], size: SIZE[:small], align: :left
    end
  end
end
