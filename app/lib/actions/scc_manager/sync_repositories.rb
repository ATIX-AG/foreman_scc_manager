module Actions
  module SccManager
    class SyncRepositories < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        plan_self(base_url: scc_account.base_url, login: scc_account.login, password: scc_account.password)
      end

      def run
        output[:data] = ::SccManager.get_scc_data(input[:base_url], '/connect/organizations/repositories', input[:login], input[:password])
      end

      def finalize
        SccAccount.find(input[:scc_account][:id]).update_scc_repositories(output[:data])
      end

      def humanized_name
        _('Sync SCC Accounts Repositories')
      end

      def humanized_output
        if task_output.blank?
          ''
        else
          'Trimmed...'
        end
      end
    end
  end
end
