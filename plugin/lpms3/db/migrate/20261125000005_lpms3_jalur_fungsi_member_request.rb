# frozen_string_literal: true

# LPMS3 1.44: persetujuan berjenjang per Fungsi (jalur FUNGSI: Pejabat Eselon 2 → Eselon 1 unit pengaju) di samping jalur
# PROYEK (Pimpro → Eselon 2 → Eselon 1 Fungsi Proyek), dan permintaan anggota proyek yang menunggu persetujuan Pimpro.
class Lpms3JalurFungsiMemberRequest < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE lpms3_approval_tasks
        ADD COLUMN IF NOT EXISTS jalur varchar(10) NOT NULL DEFAULT 'PROYEK',
        ADD COLUMN IF NOT EXISTS unit_es2_id integer,
        ADD COLUMN IF NOT EXISTS unit_es1_id integer;

      CREATE TABLE IF NOT EXISTS lpms3_member_requests (
        id bigserial PRIMARY KEY, project_id integer NOT NULL, user_id integer NOT NULL, role_ids integer[] NOT NULL DEFAULT '{}',
        requested_by integer NOT NULL, requested_at timestamptz NOT NULL DEFAULT now(),
        state varchar(12) NOT NULL DEFAULT 'menunggu' CHECK (state IN ('menunggu','disetujui','ditolak')),
        decided_by integer, decided_at timestamptz, note text);
      CREATE UNIQUE INDEX IF NOT EXISTS ux_lpms3_member_request_pending ON lpms3_member_requests(project_id, user_id) WHERE state = 'menunggu';
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS lpms3_member_requests;
      ALTER TABLE lpms3_approval_tasks DROP COLUMN IF EXISTS unit_es1_id, DROP COLUMN IF EXISTS unit_es2_id, DROP COLUMN IF EXISTS jalur;
    SQL
  end
end
