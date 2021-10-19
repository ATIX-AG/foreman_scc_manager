module Actions
  module SccManager
    class SyncPlanAccountRepositories < Actions::EntryAction
      include Actions::RecurringAction
      def plan(scc_account)
        add_missing_task_group(scc_account)
        action_subject(scc_account)

        User.as_anonymous_admin do
          plan_action(::Actions::SccManager::SyncRepositories, scc_account)
          plan_self(sync_plan_name: scc_account.name)
        end
      end

      def add_missing_task_group(sync_plan)
        if sync_plan.task_group.nil?
          sync_plan.task_group = ::SccAccountSyncPlanTaskGroup.create!
          sync_plan.save!
        end
        task.add_missing_task_groups(sync_plan.task_group)
      end

      def rescue_strategy
        # Dynflow::Action::Rescue::Skip
        # REMOVEME
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        if input.try(:[], :sync_plan_name)
          _('Update SUSE repositories %s') % (input[:sync_plan_name] || _('Unknown'))
        else
          _('Update SUSE repositories')
        end
      end
    end
  end
end
