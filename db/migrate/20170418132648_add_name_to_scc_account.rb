# frozen_string_literal: true

class AddNameToSccAccount < ActiveRecord::Migration[4.2]
  def change
    add_column :scc_accounts, :name, :string, limit: 255
  end
end
