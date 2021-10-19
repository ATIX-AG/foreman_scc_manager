# frozen_string_literal: true

module Actions
  module SccManager
    # for dynflow documentation see here: https://dynflow.github.io/documentation/
    class Sync < Actions::EntryAction
      def plan(scc_account)
        ::Foreman::Logging.logger('foreman_scc_manager')
                          .info("Initiating 'sync' for SccAccount '#{scc_account.name}'.")
        action_subject(scc_account)
        sequence do
          plan_action(::Actions::SccManager::SyncRepositories, scc_account)
          plan_action(::Actions::SccManager::SyncProducts, scc_account)
          plan_self
        end
      end

      def finalize
        # this is only executed if run actions of SyncRepositories and SyncProducts were successful
        scc_account = SccAccount.find(input[:scc_account][:id])
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
