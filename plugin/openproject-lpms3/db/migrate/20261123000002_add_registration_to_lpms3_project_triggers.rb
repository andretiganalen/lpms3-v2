# frozen_string_literal: true

# LPMS3 1.37: registrasi dan persetujuan pemicu LenO (docs/plan/RANCANGAN-PEMICU-LENO.md §6).
class AddRegistrationToLpms3ProjectTriggers < ActiveRecord::Migration[7.1]
  def change
    change_table :lpms3_project_triggers, bulk: true do |t|
      t.string :nama_proyek
      t.string :kode_proyek_lpms3
      t.text :catatan_usulan
      t.text :pembuatan_galat
      t.datetime :pembuatan_dicoba_pada
    end
  end
end
