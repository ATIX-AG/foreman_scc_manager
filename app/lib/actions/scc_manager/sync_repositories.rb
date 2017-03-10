module Actions
  module SccManager
    class SyncRepositories < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        sequence do
          scc_account.sync_scc_repositories
        end
      end

      def humanized_name
        _("Sync SCC Accounts Repositories")
      end
    end
  end
end
