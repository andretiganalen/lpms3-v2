# frozen_string_literal: true

# LPMS3: mata uang korporasi dan riwayat kurs (append-only). Kurs = nilai 1 unit mata uang dalam mata uang dasar.
class CreateLpms3Currencies < ActiveRecord::Migration[7.1]
  def up
    create_table :lpms3_currencies do |t|
      t.string :code, limit: 3, null: false
      t.string :name, null: false
      t.string :symbol, null: false
      t.integer :minor_units, null: false, default: 2
      t.boolean :active, null: false, default: true
      t.boolean :is_base, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :lpms3_currencies, :code, unique: true

    create_table :lpms3_exchange_rates do |t|
      t.string :currency_code, limit: 3, null: false
      t.decimal :rate, precision: 24, scale: 8, null: false
      t.date :valid_on, null: false
      t.string :source, null: false, default: "manual"
      t.string :note
      t.bigint :created_by_id
      t.datetime :created_at, null: false
    end
    add_index :lpms3_exchange_rates, %i[currency_code valid_on created_at], name: "idx_lpms3_rates_lookup"

    # Data awal: IDR sebagai mata uang dasar; mata uang umum, tanpa kurs (diisi oleh Keuangan atau diambil dari sumber).
    now = Time.current
    [["IDR", "Rupiah", "Rp", 0, true, true], ["USD", "Dolar Amerika Serikat", "$", 2, true, false],
     ["EUR", "Euro", "€", 2, true, false], ["SGD", "Dolar Singapura", "S$", 2, true, false],
     ["JPY", "Yen Jepang", "¥", 0, true, false], ["CNY", "Yuan Tiongkok", "CN¥", 2, false, false],
     ["AUD", "Dolar Australia", "A$", 2, false, false], ["GBP", "Pound Sterling", "£", 2, false, false]].each_with_index do |(c, n, s, mu, act, base), i|
      execute <<~SQL.squish
        INSERT INTO lpms3_currencies (code, name, symbol, minor_units, active, is_base, position, created_at, updated_at)
        VALUES (#{quote(c)}, #{quote(n)}, #{quote(s)}, #{mu}, #{act}, #{base}, #{i}, #{quote(now)}, #{quote(now)})
      SQL
    end
  end

  def down
    drop_table :lpms3_exchange_rates
    drop_table :lpms3_currencies
  end
end
