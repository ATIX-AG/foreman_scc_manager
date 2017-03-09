class AddSyncedToSccAccount < ActiveRecord::Migration
  def change
    add_column :scc_accounts, :synced, :datetime, default: nil
  end
end
