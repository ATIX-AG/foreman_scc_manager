# frozen_string_literal: true

class AddSyncStatusToSccAccount < ActiveRecord::Migration[4.2]
  def change
    add_column :scc_accounts, :sync_status, :string
  end
end
