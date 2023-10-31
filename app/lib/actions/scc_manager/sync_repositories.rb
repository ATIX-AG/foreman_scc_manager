module Actions
  module SccManager
    class SyncRepositories < Actions::EntryAction
      include EncryptValue

      def plan(scc_account)
        action_subject(scc_account)
        password = encrypt_field(scc_account.password)
        plan_self(base_url: scc_account.base_url,
          login: scc_account.login,
          password: password)
      end

      def run
        output[:data] = ::SccManager.get_scc_data(input[:base_url],
          '/connect/organizations/repositories',
          input[:login],
          decrypt_field(input[:password]))
      rescue StandardError => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Error while syncronizing SCC-Repositories: #{e}"
        error! e.to_s
      end

      def finalize
        # this is only executed if 'run' succeeds
        SccAccount.find(input[:scc_account][:id]).update_scc_repositories(output[:data])
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Sync SUSE subscriptions (Repositories)')
      end

      def humanized_output
        output.dup.update(data: "Trimmed (got #{output[:data]&.length} repositories")
      end
    end
  end
end
