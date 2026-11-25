# frozen_string_literal: true

# LPMS3: Kick-Off per proyek. Admin Fungsi Pengawasan Proyek menunjuk Project Analis; Project Analis mengundang
# seluruh stakeholder proyek ke rapat Kick-Off (BOP-001 §5.2.2).
class CreateLpms3Kickoffs < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_kickoffs do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects }, index: { unique: true }
      t.string :state, null: false, default: "menunggu_analis" # menunggu_analis | menunggu_undangan | terkirim
      t.bigint :assigned_by_id
      t.datetime :assigned_at
      t.bigint :analis_id
      t.bigint :invited_by_id
      t.datetime :invited_at
      t.datetime :scheduled_at
      t.text :agenda
      t.jsonb :invitees, null: false, default: []
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
  end
end
