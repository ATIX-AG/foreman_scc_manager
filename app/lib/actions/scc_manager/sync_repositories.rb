module Actions
  module SccManager
    class SyncRepositories < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        plan_self(id: scc_account.id, base_url: scc_account.base_url, login: scc_account.login, password: scc_account.password)
      end

      def run
        output[:data] = ::SccManager::get_scc_data(input.fetch(:base_url), '/connect/organizations/repositories', input.fetch(:login), input.fetch(:password))
      end

      def finalize
        SccAccount.find(input.fetch(:id)).update_scc_repositories(output.fetch(:data))
      end

      def humanized_name
        _("Sync SCC Accounts Repositories")
      end
    end
  end
end
