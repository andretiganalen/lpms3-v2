# frozen_string_literal: true

# LPMS3 1.42: monitoring Kontrak awal (kontrak proyek dengan pemberi kerja).
# Data dasar kontrak tetap di atribut proyek (Nomor/Tanggal/Nilai Kontrak, Tanggal Selesai Kontrak, Nomor Adendum
# Terakhir); tabel ini menyimpan nilai awal, Go/No-Go (SFR-028/SFR-024), jaminan, termin pembayaran, dan adendum (SFR-025).
class CreateLpms3Kontrak < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS lpms3.kontrak (
        project_id integer PRIMARY KEY,
        nilai_awal numeric(20,2), tanggal_selesai_awal date, tanggal_mulai date,
        posisi_len text CHECK (posisi_len IN ('Kontraktor Utama','Sub-Kontraktor','Retail')),
        term_of_payment text,
        go_nogo text NOT NULL DEFAULT 'BELUM' CHECK (go_nogo IN ('BELUM','GO','NO_GO')),
        go_nogo_tanggal date, go_nogo_nomor text,
        catatan text, updated_by integer, updated_at timestamptz NOT NULL DEFAULT now());

      CREATE TABLE IF NOT EXISTS lpms3.kontrak_jaminan (
        id bigserial PRIMARY KEY, project_id integer NOT NULL,
        jenis text NOT NULL CHECK (jenis IN ('UANG_MUKA','PELAKSANAAN','PEMELIHARAAN','PEMBAYARAN','PENAWARAN','LAINNYA')),
        nomor text NOT NULL, penerbit text, nilai numeric(20,2), persen numeric(5,2),
        berlaku_dari date, berlaku_sampai date NOT NULL,
        status text NOT NULL DEFAULT 'AKTIF' CHECK (status IN ('AKTIF','DIKEMBALIKAN','DICAIRKAN')),
        catatan text, created_by integer, updated_by integer, updated_at timestamptz NOT NULL DEFAULT now());
      CREATE INDEX IF NOT EXISTS ix_lpms3_kontrak_jaminan_project ON lpms3.kontrak_jaminan(project_id);

      CREATE TABLE IF NOT EXISTS lpms3.kontrak_termin (
        id bigserial PRIMARY KEY, project_id integer NOT NULL, urutan integer NOT NULL,
        uraian text NOT NULL, persen numeric(6,3) NOT NULL CHECK (persen > 0 AND persen <= 100),
        syarat text NOT NULL DEFAULT 'PROGRES' CHECK (syarat IN ('UANG_MUKA','PROGRES','AKTIVITAS','BAST','MANUAL')),
        syarat_progres numeric(6,3), syarat_wbs_node_id bigint, rencana_tanggal date,
        status text NOT NULL DEFAULT 'RENCANA' CHECK (status IN ('RENCANA','DITAGIH','DIBAYAR')),
        tanggal_tagih date, nomor_tagihan text, tanggal_bayar date, nilai_bayar numeric(20,2),
        catatan text, created_by integer, updated_by integer, updated_at timestamptz NOT NULL DEFAULT now(),
        UNIQUE (project_id, urutan));

      CREATE TABLE IF NOT EXISTS lpms3.kontrak_adendum (
        id bigserial PRIMARY KEY, project_id integer NOT NULL, urutan integer NOT NULL,
        nomor_dokumen text NOT NULL, tanggal date NOT NULL, uraian text NOT NULL,
        nilai_baru numeric(20,2), tanggal_selesai_baru date, lingkup boolean NOT NULL DEFAULT false,
        sfr025_nomor text, change_request_id integer,
        nilai_sebelum numeric(20,2), tanggal_selesai_sebelum date,
        status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','DISAHKAN')),
        created_by integer, disahkan_by integer, disahkan_at timestamptz,
        updated_at timestamptz NOT NULL DEFAULT now(),
        UNIQUE (project_id, urutan));
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS lpms3.kontrak_adendum;
      DROP TABLE IF EXISTS lpms3.kontrak_termin;
      DROP TABLE IF EXISTS lpms3.kontrak_jaminan;
      DROP TABLE IF EXISTS lpms3.kontrak;
    SQL
  end
end
