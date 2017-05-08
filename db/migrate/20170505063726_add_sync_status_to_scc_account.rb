class AddSyncStatusToSccAccount < ActiveRecord::Migration
  def change
    add_column :scc_accounts, :sync_status, :string
  end
end
