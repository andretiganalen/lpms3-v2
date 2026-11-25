# frozen_string_literal: true

# LPMS3 LenO Mobile: status pengajuan WO ke Pejabat Eselon 2 dan laporan harian per WO.
class CreateLpms3LenoMobile < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_wo_reviews do |t|
      t.references :work_package, null: false, foreign_key: { to_table: :work_packages }, index: { unique: true }
      t.string :state, null: false, default: "berjalan"
      t.datetime :submitted_at
      t.datetime :decided_at
      t.bigint :decided_by_id
      t.text :reject_reason
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    create_table :lpms3_daily_reports do |t|
      t.references :work_package, null: false, foreign_key: { to_table: :work_packages }
      t.date :report_date, null: false
      t.decimal :progress, precision: 5, scale: 1, null: false, default: 0
      t.decimal :prev_progress, precision: 5, scale: 1, null: false, default: 0
      t.string :execution, null: false, default: "sesuai"
      t.text :keterangan
      t.text :kendala
      t.string :status, null: false, default: "draft"
      t.datetime :sent_at
      t.bigint :author_id
      t.jsonb :photo_ids, null: false, default: []
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lpms3_daily_reports, %i[work_package_id report_date], unique: true, name: "idx_lpms3_daily_wo_date"
  end
end
