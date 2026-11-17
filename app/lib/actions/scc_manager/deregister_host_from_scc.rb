module Actions
  module SccManager
    class DeregisterHostFromScc < Actions::EntryAction
      def plan(scc_host_credentials_id)
        plan_self(base_url: 'https://scc.suse.com',
          scc_host_credentials_id: scc_host_credentials_id)
      end

      def run
        scc_host_credentials = SccHostCredentials.find_by!(id: input[:scc_host_credentials_id])
        scc_login = scc_host_credentials.scc_login
        scc_password = scc_host_credentials.scc_password
        encoded_credentials = Base64.strict_encode64("#{scc_login}:#{scc_password}")
        auth_header = { Authorization: "Basic #{encoded_credentials}" }

        # SCC does not log an event when a system without activated products is de-registered.
        # The de-registration still works: afterwards SCC rejects the system's
        # credentials with 401. This is expected SCC behaviour, not a bug.
        ::SccManager.delete_scc_data(input[:base_url],
          '/connect/systems',
          auth_header)
      rescue RestClient::Exception => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Could not connect to SCC portal: #{e}"
        error! "Could not connect to SCC portal: #{e}"
      rescue StandardError => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Error while deregistering host from SCC: #{e}"
        error! "Error while deregistering host from SCC: #{e}"
      end

      def finalize
        scc_host_credentials = SccHostCredentials.find_by(id: input[:scc_host_credentials_id])
        scc_host_credentials&.scc_facet&.destroy!
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Deregister host from SCC')
      end

      def humanized_output
        output.dup.update(message: 'Deregistered host from SCC')
      end
    end
  end
end
