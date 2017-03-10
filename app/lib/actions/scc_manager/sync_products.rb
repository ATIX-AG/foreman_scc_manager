module Actions
  module SccManager
    class SyncProducts < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        sequence do
          scc_account.sync_scc_products
        end
      end

      def humanized_name
        _("Sync SCC Accounts Products")
      end
    end
  end
end
