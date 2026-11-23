# frozen_string_literal: true

# LPMS3 1.39: catatan member proyek yang ditambahkan otomatis (tim default berjenjang, atasan Eselon 2 Pimpro).
class CreateLpms3AutoMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_auto_members do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }
      t.bigint :user_id, null: false
      t.string :role_name, null: false
      t.string :alasan, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
    add_index :lpms3_auto_members, %i[project_id user_id role_name]
    reversible do |dir|
      dir.up { execute "CREATE INDEX IF NOT EXISTS ix_lpms3_user_position_user ON lpms3.user_position(user_id)" }
      dir.down { execute "DROP INDEX IF EXISTS lpms3.ix_lpms3_user_position_user" }
    end
  end
end
