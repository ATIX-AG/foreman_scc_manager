module Actions
  module SccManager
    class GetSccHostCredentials < Actions::EntryAction
      def plan(host_data, host_id, reg_code)
        plan_self(base_url: 'https://scc.suse.com',
          reg_code: reg_code,
          host_data: host_data,
          host_id: host_id)
      end

      def run
        auth_header = { Authorization: "Token token=#{input[:reg_code]}" }
        payload = input[:host_data].to_json

        response = ::SccManager.post_scc_data(input[:base_url],
          '/connect/subscriptions/systems',
          auth_header,
          payload)
        results = JSON.parse(response)
        host = ::Host::Managed.find(input[:host_id])
        scc_facet = host.scc_facet || host.create_scc_facet
        credentials = SccHostCredentials.find_or_create_by(scc_facet: scc_facet)
        credentials.scc_login = results['login']
        credentials.scc_password = results['password']
        credentials.save!
      rescue RestClient::Exception => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Could not connect to SCC portal: #{e}"
        error! "Could not connect to SCC portal: #{e}"
      rescue ActiveRecord::RecordNotFound => e
        ::Foreman::Logging.logger('foreman_scc_manager').error e.to_s
        error! e.to_s
      rescue StandardError => e
        ::Foreman::Logging.logger('foreman_scc_manager').error "Error while announcing host to SCC: #{e}"
        error! "Error while announcing host to SCC: #{e}"
      end

      def rescue_strategy
        Dynflow::Action::Rescue::Fail
      end

      def humanized_name
        _('Announce host to SCC')
      end

      def humanized_output
        output.dup.update(message: 'Announced host to SCC')
      end
    end
  end
end
