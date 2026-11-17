module Actions
  module SccManager
    class DeactivateProductOnScc < Actions::EntryAction
      def plan(scc_host_credentials_id, product_data, scc_host_product_id)
        plan_self(base_url: 'https://scc.suse.com',
          scc_host_credentials_id: scc_host_credentials_id,
          product_data: product_data,
          scc_host_product_id: scc_host_product_id)
      end

      def run
        scc_host_credentials = SccHostCredentials.find_by!(id: input[:scc_host_credentials_id])
        encoded_credentials = Base64.strict_encode64("#{scc_host_credentials.scc_login}:#{scc_host_credentials.scc_password}")
        auth_header = { Authorization: "Basic #{encoded_credentials}" }
        payload = input[:product_data].to_json

        ::SccManager.delete_scc_data(input[:base_url],
          '/connect/systems/products',
          auth_header,
          payload)
      rescue RestClient::Exception => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Could not connect to SCC portal: #{e}"
        error! "Could not connect to SCC portal: #{e}"
      rescue StandardError => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Error while deactivating product for host: #{e}"
        error! "Error while deactivating product for host: #{e}"
      end

      def finalize
        SccHostProduct.find_by(id: input[:scc_host_product_id])&.destroy!
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Deactivate a product on SCC for a host')
      end

      def humanized_output
        output.dup.update(message: 'Deactivated product for host')
      end
    end
  end
end
