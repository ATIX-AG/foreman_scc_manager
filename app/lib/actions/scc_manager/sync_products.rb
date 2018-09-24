module Actions
  module SccManager
    class SyncProducts < Actions::EntryAction
      def plan(scc_account)
        action_subject(scc_account)
        plan_self(id: scc_account.id,
                  base_url: scc_account.base_url,
                  login: scc_account.login,
                  password: scc_account.password)
      end

      def run
        output[:status] = 'SUCCESS'
        begin
          products = ::SccManager.get_scc_data(input.fetch(:base_url),
                                               '/connect/organizations/products',
                                               input.fetch(:login),
                                               input.fetch(:password))
          output[:data] = ::SccManager.sanitize_products(products).values
        rescue StandardError
          output[:status] = 'FAILURE'
        end
      end

      def finalize
        SccAccount.find(input.fetch(:id)).update_scc_products(output.fetch(:data)) if output[:status] == 'SUCCESS'
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Sync SUSE subscriptions (Products)')
      end
    end
  end
end
