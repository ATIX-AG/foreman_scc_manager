module Actions
  module SccManager
    class SyncProducts < Actions::EntryAction
      include EncryptValue

      def plan(scc_account)
        action_subject(scc_account)
        password = encrypt_field(scc_account.password)
        plan_self(id: scc_account.id,
                  base_url: scc_account.base_url,
                  login: scc_account.login,
                  password: password)
      end

      def run
        output[:status] = 'SUCCESS'
        begin
          products = ::SccManager.get_scc_data(input.fetch(:base_url),
                                               '/connect/organizations/products',
                                               input.fetch(:login),
                                               decrypt_field(input.fetch(:password)))
          output[:data] = ::SccManager.sanitize_products(products).values
        rescue StandardError => e
          ::Foreman::Logging.logger('foreman_scc_manager').error "Error while syncronizing SCC-Products: #{e}"
          output[:status] = 'FAILURE'
          error! e.to_s
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

      def humanized_output
        output.dup.update(data: 'Trimmed')
      end
    end
  end
end
