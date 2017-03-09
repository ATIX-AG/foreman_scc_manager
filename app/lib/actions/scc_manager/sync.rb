module Actions
  module SccManager
    class Sync < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        sequence do
          scc_account.sync_scc_products
        end
      end

      def finalize
      end

      def humanized_name
        _("Sync SCC Account")
      end
    end
  end
end
