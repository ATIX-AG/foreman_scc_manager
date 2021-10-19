class AddRecurringSync < ActiveRecord::Migration[5.2]
  class FakeSccAccount < ApplicationRecord
    self.table_name = 'scc_accounts'
  end

  def up
    add_column :scc_accounts, :foreman_tasks_recurring_logic_id, :integer
    add_column :scc_accounts, :interval, :string, default: 'never'
    add_column :scc_accounts, :sync_date, :datetime
    add_foreign_key :scc_accounts, :foreman_tasks_recurring_logics,
      name: 'scc_accounts_foreman_tasks_recurring_logic_fk', column: 'foreman_tasks_recurring_logic_id'
    add_column :scc_accounts, :task_group_id, :integer, index: true
    add_foreign_key :scc_accounts, :foreman_tasks_task_groups, column: :task_group_id
    FakeSccAccount.all.each do |scca|
      scca.task_group_id ||= SccAccountSyncPlanTaskGroup.create!.id
      scca.save!
    end
  end

  def down
    remove_column :scc_accounts, :foreman_tasks_recurring_logic_id
    remove_column :scc_accounts, :interval
    remove_column :scc_accounts, :sync_date
    remove_column :scc_accounts, :task_group_id
    ForemanTasks::TaskGroup.where(type: 'SccAccountSyncPlanTaskGroup').delete_all
  end
end
