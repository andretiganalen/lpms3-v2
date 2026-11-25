# frozen_string_literal: true

# LPMS3: persetujuan berjenjang per dokumen (Staff → Pimpro → Pejabat Eselon 2).
# Satu tugas aktif (menunggu) per WP; Pejabat Eselon 2 boleh langsung memutuskan tanpa melalui Pimpro (bypass).
class CreateLpms3ApprovalTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_approval_tasks do |t|
      t.references :work_package, null: false, foreign_key: { to_table: :work_packages }
      t.references :project, null: false, foreign_key: { to_table: :projects }
      t.string :stage, null: false                      # pimpro | eselon2
      t.string :state, null: false, default: "menunggu" # menunggu | diteruskan | disetujui | revisi
      t.bigint :requested_by_id, null: false
      t.datetime :requested_at, null: false
      t.text :requester_note
      t.bigint :decided_by_id
      t.datetime :decided_at
      t.text :decision_note
      t.boolean :bypassed, null: false, default: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :lpms3_approval_tasks, :work_package_id,
              unique: true, where: "state = 'menunggu'", name: "idx_lpms3_approval_one_pending_per_wp"
  end
end
