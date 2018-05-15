class AddSyncedToSccAccount < ActiveRecord::Migration[4.2]
  def change
    add_column :scc_accounts, :synced, :datetime, default: nil
  end
end
