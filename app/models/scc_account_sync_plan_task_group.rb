class SccAccountSyncPlanTaskGroup < ::ForemanTasks::TaskGroup
  has_one :scc_account, :foreign_key => :task_group_id, :dependent => :nullify, :inverse_of => :task_group, :class_name => 'SccAccount'

  def resource_name
    N_('SUSE Subscription')
  end
end
