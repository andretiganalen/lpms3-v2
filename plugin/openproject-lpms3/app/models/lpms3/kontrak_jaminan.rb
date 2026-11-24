# frozen_string_literal: true

module Lpms3
  # Jaminan kontrak (bank garansi / surety bond) dengan masa berlaku.
  class KontrakJaminan < ::ApplicationRecord
    self.table_name = "lpms3.kontrak_jaminan"

    JENIS = { "UANG_MUKA" => "Jaminan Uang Muka", "PELAKSANAAN" => "Jaminan Pelaksanaan", "PEMELIHARAAN" => "Jaminan Pemeliharaan",
              "PEMBAYARAN" => "Jaminan Pembayaran", "PENAWARAN" => "Jaminan Penawaran", "LAINNYA" => "Jaminan Lainnya" }.freeze
    STATUS = { "AKTIF" => "Aktif", "DIKEMBALIKAN" => "Dikembalikan", "DICAIRKAN" => "Dicairkan" }.freeze

    belongs_to :project, class_name: "::Project"

    def aktif? = status == "AKTIF"
    def label = JENIS.fetch(jenis, jenis)
    def sisa_hari(today = Date.current) = (berlaku_sampai - today).to_i
  end
end
