# frozen_string_literal: true

# LPMS3 1.41: baseline WBS otomatis.
#  - lpms3.baseline mendapat status DRAFT/ACTIVE/SUPERSEDED/REJECTED; satu draft dan satu aktif per proyek.
#    change_request_form_id = work package "Change Request" (BFR-001) yang mengaktifkan draft.
#  - baseline_item menyimpan struktur (induk, urutan, weigh factor) agar WBS bisa dikembalikan ke baseline aktif,
#    dan tanda frozen untuk pekerjaan selesai.
#  - wbs_done_snapshot: rekam aktivitas saat mencapai 100 %; baseline berikutnya memakai nilai ini.
class Lpms3BaselineDraft < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE lpms3.baseline
        ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'DRAFT',
        ADD COLUMN IF NOT EXISTS created_by integer,
        ADD COLUMN IF NOT EXISTS change_summary text,
        ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
      ALTER TABLE lpms3.baseline DROP CONSTRAINT IF EXISTS baseline_status_check;
      ALTER TABLE lpms3.baseline ADD CONSTRAINT baseline_status_check
        CHECK (status IN ('DRAFT','ACTIVE','SUPERSEDED','REJECTED'));
      CREATE UNIQUE INDEX IF NOT EXISTS ux_lpms3_baseline_draft ON lpms3.baseline(project_id) WHERE status = 'DRAFT';
      CREATE UNIQUE INDEX IF NOT EXISTS ux_lpms3_baseline_active ON lpms3.baseline(project_id) WHERE is_active;
      CREATE INDEX IF NOT EXISTS ix_lpms3_baseline_cr ON lpms3.baseline(change_request_form_id) WHERE change_request_form_id IS NOT NULL;

      ALTER TABLE lpms3.baseline_item
        ADD COLUMN IF NOT EXISTS parent_wbs_node_id bigint,
        ADD COLUMN IF NOT EXISTS weigh_factor numeric(9,6),
        ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0,
        ADD COLUMN IF NOT EXISTS is_frozen boolean NOT NULL DEFAULT false;

      CREATE TABLE IF NOT EXISTS lpms3.wbs_done_snapshot (
        wbs_node_id bigint PRIMARY KEY REFERENCES lpms3.wbs_node(id) ON DELETE CASCADE,
        project_id integer NOT NULL, work_package_id integer,
        wbs_code text NOT NULL, tasks text NOT NULL, level text NOT NULL,
        weigh_factor numeric(9,6), weight numeric(12,9),
        date_plan_start date, date_plan_finish date, date_actual_start date, date_actual_finish date,
        harga_pekerjaan numeric(20,2), pic_user_id integer,
        frozen_by integer, frozen_at timestamptz NOT NULL DEFAULT now());
      CREATE INDEX IF NOT EXISTS ix_lpms3_wbs_done_snapshot_project ON lpms3.wbs_done_snapshot(project_id);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS lpms3.wbs_done_snapshot;
      ALTER TABLE lpms3.baseline_item DROP COLUMN IF EXISTS is_frozen, DROP COLUMN IF EXISTS sort_order,
        DROP COLUMN IF EXISTS weigh_factor, DROP COLUMN IF EXISTS parent_wbs_node_id;
      DROP INDEX IF EXISTS lpms3.ix_lpms3_baseline_cr;
      DROP INDEX IF EXISTS lpms3.ux_lpms3_baseline_active;
      DROP INDEX IF EXISTS lpms3.ux_lpms3_baseline_draft;
      ALTER TABLE lpms3.baseline DROP CONSTRAINT IF EXISTS baseline_status_check;
      ALTER TABLE lpms3.baseline DROP COLUMN IF EXISTS updated_at, DROP COLUMN IF EXISTS change_summary,
        DROP COLUMN IF EXISTS created_by, DROP COLUMN IF EXISTS status;
    SQL
  end
end
