# frozen_string_literal: true

# LPMS3 1.43: master rekanan (PFR-001), evaluasi penyedia (PFR-019), daftar hitam (PFR-030), dan tautan Item Pengadaan
# ke aktivitas WBS (progres aktivitas mengikuti tahap pengadaan).
class CreateLpms3RekananPengadaanWbs < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS lpms3.rekanan (
        id bigserial PRIMARY KEY, nama text NOT NULL, npwp text, alamat text, kontak text, kategori text,
        status text NOT NULL DEFAULT 'AKTIF' CHECK (status IN ('AKTIF','DAFTAR_HITAM')),
        alasan_hitam text, tanggal_hitam date, dihitamkan_by integer,
        created_by integer, updated_by integer, updated_at timestamptz NOT NULL DEFAULT now());
      CREATE UNIQUE INDEX IF NOT EXISTS ux_lpms3_rekanan_nama ON lpms3.rekanan (lower(nama));

      CREATE TABLE IF NOT EXISTS lpms3.rekanan_evaluasi (
        id bigserial PRIMARY KEY, rekanan_id bigint NOT NULL REFERENCES lpms3.rekanan(id),
        work_package_id integer NOT NULL UNIQUE, project_id integer NOT NULL,
        skor_mutu smallint NOT NULL CHECK (skor_mutu BETWEEN 1 AND 5), skor_waktu smallint NOT NULL CHECK (skor_waktu BETWEEN 1 AND 5),
        skor_harga smallint NOT NULL CHECK (skor_harga BETWEEN 1 AND 5), skor_k3l smallint NOT NULL CHECK (skor_k3l BETWEEN 1 AND 5),
        catatan text, evaluator_id integer NOT NULL, tanggal date NOT NULL DEFAULT CURRENT_DATE, created_at timestamptz NOT NULL DEFAULT now());

      CREATE TABLE IF NOT EXISTS lpms3.pengadaan_wbs (
        work_package_id integer PRIMARY KEY, wbs_node_id bigint NOT NULL REFERENCES lpms3.wbs_node(id) ON DELETE CASCADE,
        updated_by integer, updated_at timestamptz NOT NULL DEFAULT now());
      CREATE INDEX IF NOT EXISTS ix_lpms3_pengadaan_wbs_node ON lpms3.pengadaan_wbs(wbs_node_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS lpms3.pengadaan_wbs;
      DROP TABLE IF EXISTS lpms3.rekanan_evaluasi;
      DROP TABLE IF EXISTS lpms3.rekanan;
    SQL
  end
end
