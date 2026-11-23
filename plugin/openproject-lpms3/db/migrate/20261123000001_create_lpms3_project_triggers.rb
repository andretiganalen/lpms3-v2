# frozen_string_literal: true

# LPMS3: pemicu proyek dari LenO (docs/plan/RANCANGAN-PEMICU-LENO.md §5). Satu baris per kode proyek;
# setiap perpindahan status dan kiriman ulang dicatat append-only di lpms3_project_trigger_events.
class CreateLpms3ProjectTriggers < ActiveRecord::Migration[7.1]
  def change
    create_table :lpms3_project_triggers do |t|
      t.string :kode_proyek, null: false, index: { unique: true }
      t.bigint :lpms2_proyek_id
      t.string :status, null: false, default: "diterima"
      t.string :id_kiriman_terakhir, null: false
      t.integer :jumlah_kiriman, null: false, default: 1
      t.datetime :diterima_pada, null: false
      t.datetime :kiriman_terakhir_pada, null: false
      t.datetime :dikirim_pada
      t.jsonb :nota, null: false, default: {}
      t.datetime :diklaim_pada
      t.jsonb :snapshot
      t.datetime :snapshot_pada
      t.text :snapshot_galat
      t.string :template_identifier
      t.bigint :pimpro_id
      t.bigint :vp_id
      t.bigint :diusulkan_oleh_id
      t.datetime :diusulkan_pada
      t.bigint :diputus_oleh_id
      t.datetime :diputus_pada
      t.text :catatan_keputusan
      t.references :project, foreign_key: { to_table: :projects }, index: { unique: true }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :lpms3_project_triggers, %i[status diterima_pada]

    create_table :lpms3_project_trigger_events do |t|
      t.references :project_trigger, null: false, foreign_key: { to_table: :lpms3_project_triggers, on_delete: :restrict }
      t.string :kind, null: false
      t.string :from_status
      t.string :to_status
      t.bigint :actor_id
      t.string :sumber, null: false, default: "leno"
      t.text :note
      t.datetime :created_at, null: false
    end
  end
end
