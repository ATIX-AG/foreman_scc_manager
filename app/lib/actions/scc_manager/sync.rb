module Actions
  module SccManager
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
        scc_account = SccAccount.find(input[:scc_account][:id])
        scc_account.synced = DateTime.current
        scc_account.save!
      end

      def humanized_name
        _('Sync SUSE subscriptions')
      end
    end
  end
end
