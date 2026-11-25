# frozen_string_literal: true

# LPMS3 1.41: "frozen" bentrok dengan Object#frozen? di ActiveRecord; kolom diganti is_frozen.
class RenameLpms3BaselineItemFrozen < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      DO $$ BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'lpms3' AND table_name = 'baseline_item' AND column_name = 'frozen') THEN
          ALTER TABLE lpms3.baseline_item RENAME COLUMN frozen TO is_frozen;
        END IF;
      END $$;
      ALTER TABLE lpms3.baseline_item ADD COLUMN IF NOT EXISTS is_frozen boolean NOT NULL DEFAULT false;
    SQL
  end

  def down
    execute "ALTER TABLE lpms3.baseline_item RENAME COLUMN is_frozen TO frozen"
  end
end
