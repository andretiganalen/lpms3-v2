# frozen_string_literal: true

# LPMS3: masukan pembaca (mode Baca Saja) ke pembuat dokumen, tanpa mengubah status persetujuan.
class CreateLpms3Feedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_feedbacks do |t|
      t.references :work_package, null: false, foreign_key: { to_table: :work_packages }
      t.references :project, null: false, foreign_key: { to_table: :projects }
      t.bigint :given_by_id, null: false
      t.bigint :author_id, null: false
      t.text :body, null: false
      t.string :state, null: false, default: "terbuka" # terbuka | diperbaiki
      t.datetime :given_at, null: false
      t.bigint :resolved_by_id
      t.datetime :resolved_at
      t.text :resolution_note
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lpms3_feedbacks, %i[author_id state]
  end
end
