# frozen_string_literal: true

class CreateSccRepositories < ActiveRecord::Migration[4.2]
  def change
    create_table :scc_repositories do |t|
      t.references :scc_account, index: true, foreign_key: true
      t.integer :scc_id, unique: true
      t.string :name, limit: 255
      t.string :distro_target, limit: 255
      t.string :description, limit: 255
      t.string :url, limit: 255
      t.string :token, limit: 255
      t.boolean :enabled
      t.boolean :autorefresh
      t.boolean :installer_updates

      t.timestamps null: false
    end
  end
end
