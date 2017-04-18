class AddNameToSccAccount < ActiveRecord::Migration
  def change
    add_column :scc_accounts, :name, :string, limit: 255
  end
end
