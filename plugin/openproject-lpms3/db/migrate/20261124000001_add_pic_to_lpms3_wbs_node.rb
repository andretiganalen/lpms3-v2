# frozen_string_literal: true

# LPMS3 1.40: kolom "PIC & Resource" pada WBS. PIC = anggota proyek (pic_user_id) atau, bila belum ada, unit
# Eselon 1 Fungsi induknya (pic_unit_id) yang kemudian menugaskan timnya.
class AddPicToLpms3WbsNode < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE lpms3.wbs_node
        ADD COLUMN IF NOT EXISTS pic_user_id integer,
        ADD COLUMN IF NOT EXISTS pic_unit_id integer,
        ADD COLUMN IF NOT EXISTS pic_assigned_by integer,
        ADD COLUMN IF NOT EXISTS pic_assigned_at timestamptz;
      -- Template (sheet Settings) memakai Level 0-7 dan "Level n Activity"; cek lama menolak mis. "Level 5" berinduk.
      ALTER TABLE lpms3.wbs_node DROP CONSTRAINT IF EXISTS wbs_node_level_check;
      ALTER TABLE lpms3.wbs_node ADD CONSTRAINT wbs_node_level_check CHECK (level ~ '^Level [0-7]( Activity)?$');
      CREATE INDEX IF NOT EXISTS ix_lpms3_wbs_node_tree ON lpms3.wbs_node(project_id, parent_id, sort_order);
      CREATE INDEX IF NOT EXISTS ix_lpms3_wbs_node_pic_unit ON lpms3.wbs_node(pic_unit_id) WHERE pic_unit_id IS NOT NULL AND pic_user_id IS NULL;
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS lpms3.ix_lpms3_wbs_node_pic_unit;
      DROP INDEX IF EXISTS lpms3.ix_lpms3_wbs_node_tree;
      ALTER TABLE lpms3.wbs_node DROP COLUMN IF EXISTS pic_assigned_at, DROP COLUMN IF EXISTS pic_assigned_by,
        DROP COLUMN IF EXISTS pic_unit_id, DROP COLUMN IF EXISTS pic_user_id;
    SQL
  end
end
