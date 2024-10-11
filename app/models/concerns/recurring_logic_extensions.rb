module RecurringLogicExtensions
  extend ActiveSupport::Concern

  included do
    has_one :scc_account, :inverse_of => :foreman_tasks_recurring_logic, :class_name => 'SccAccount'
  end
end
