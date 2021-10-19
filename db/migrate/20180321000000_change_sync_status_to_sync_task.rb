# frozen_string_literal: true

class ChangeSyncStatusToSyncTask < ActiveRecord::Migration[4.2]
  def change
    remove_column :scc_accounts, :sync_status, :string
    add_column :scc_accounts, :sync_task_id, :uuid, null: true
    # add_foreign_key "scc_accounts", "foreman_tasks_tasks", name: "scc_accounts_foreman_tasks_tasks_id_fk", column: "sync_task_id", primary_key: "id" , on_delete: :nullify
  end
end
