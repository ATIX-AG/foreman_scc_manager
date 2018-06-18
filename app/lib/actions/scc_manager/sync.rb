module Actions
  module SccManager
    class Sync < Actions::EntryAction
      def plan(scc_account)
        ::Foreman::Logging.logger('foreman_scc_manager')
                          .info("Initiating 'sync' for SccAccount '#{scc_account.name}'.")
        action_subject(scc_account)
        sequence do
          sync_repo_action = plan_action(::Actions::SccManager::SyncRepositories, scc_account)
          sync_prod_action = plan_action(::Actions::SccManager::SyncProducts, scc_account)
          plan_self(repo_status: sync_repo_action.output[:status], prod_status: sync_prod_action.output[:status])
        end
      end

      def finalize
        scc_account = SccAccount.find(input[:scc_account][:id])
        raise 'Updating failed' unless input[:repo_status] == 'SUCCESS' && input[:prod_status] == 'SUCCESS'
        scc_account.update! synced: Time.current
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Sync SUSE subscriptions')
      end
    end
  end
end
