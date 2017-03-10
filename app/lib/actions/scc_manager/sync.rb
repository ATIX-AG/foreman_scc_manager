module Actions
  module SccManager
    class Sync < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        sequence do
          plan_action(::Actions::SccManager::SyncRepositories, scc_account)
          plan_action(::Actions::SccManager::SyncProducts, scc_account)
          scc_account.synced = DateTime.now
          scc_account.save!
        end
      end

      def humanized_name
        _("Sync SCC Account")
      end
    end
  end
end
