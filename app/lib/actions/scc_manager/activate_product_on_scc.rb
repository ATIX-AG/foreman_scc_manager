module Actions
  module SccManager
    class ActivateProductOnScc < Actions::EntryAction
      def plan(scc_host_credentials_id, product_data, scc_host_product_id = nil)
        plan_self(base_url: 'https://scc.suse.com',
          scc_host_credentials_id: scc_host_credentials_id,
          product_data: product_data,
          scc_host_product_id: scc_host_product_id)
      end

      def run
        scc_host_credentials = SccHostCredentials.find_by!(id: input[:scc_host_credentials_id])
        scc_login = scc_host_credentials.scc_login
        scc_password = scc_host_credentials.scc_password
        encoded_credentials = Base64.strict_encode64("#{scc_login}:#{scc_password}")
        auth_header = { Authorization: "Basic #{encoded_credentials}" }
        payload = input[:product_data].to_json

        output[:data] = ::SccManager.post_scc_data(input[:base_url],
          '/connect/systems/products',
          auth_header,
          payload)
      rescue ActiveRecord::RecordNotFound => e
        mark_failed
        ::Foreman::Logging.logger('foreman_scc_manager').error "There are no SCC credentials available for the host. Product cannot be activated: #{e}"
        error! 'There are no SCC credentials available for the host. Product cannot be activated.'
      rescue RestClient::Exception => e
        mark_failed
        ::Foreman::Logging.logger('foreman_scc_manager').error "Could not connect to SCC portal: #{e}"
        error! "Could not connect to SCC portal: #{e}"
      rescue StandardError => e
        mark_failed
        ::Foreman::Logging.logger('foreman_scc_manager').error "Error activating product for host: #{e}"
        error! "Error activating product for host: #{e}"
      end

      def finalize
        scc_host_product&.update(status: SccHostProduct::ACTIVE)
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Activate a product on SCC for a host')
      end

      def humanized_output
        output.dup.update(message: 'Activated product for host')
      end

      private

      def scc_host_product
        return nil unless input[:scc_host_product_id]
        SccHostProduct.find_by(id: input[:scc_host_product_id])
      end

      def mark_failed
        scc_host_product&.update(status: SccHostProduct::FAILED)
      end
    end
  end
end
