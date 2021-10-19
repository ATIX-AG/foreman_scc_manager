# frozen_string_literal: true

class CreateSccProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :scc_products do |t|
      t.references :scc_account, index: true, foreign_key: true
      t.integer :scc_id, unique: true
      t.string :name, limit: 255
      t.string :version, limit: 63
      t.string :arch, limit: 31
      t.string :friendly_name, limit: 255
      t.string :description
      t.string :repositories

      t.timestamps null: false
    end
  end
end
