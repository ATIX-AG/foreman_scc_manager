require 'test_plugin_helper'

module ForemanSccManager
  class GetSccHostCredentialsActionTest < ActiveSupport::TestCase
    include Dynflow::Testing

    def setup
      @host = FactoryBot.create(:host,
        :managed,
        :on_compute_resource,
        operatingsystem: FactoryBot.create(:suse, :with_archs, :with_media))
      @action_class = ::Actions::SccManager::GetSccHostCredentials
      @facet = @host.create_scc_facet
      @credentials = FactoryBot.create(:scc_host_credentials, scc_facet: @facet)
      @credentials.scc_login = nil
      @credentials.scc_password = nil
    end

    def get_host_data(host)
      {
        hostname: host.name,
        hwinfo: {
          uuid: host.uuid,
          cpus: nil,
          vcpus: nil,
          sockets: nil,
          mem_total: nil,
          arch: host&.architecture&.name,
          hypervisor: host&.compute_resource&.type&.delete_prefix('Foreman::Model::'),
          cloud_provider: '',
          container_runtime: nil,
          uname: '',
          nodes: nil,
          clusters: nil,
          server_url: '',
          arch_specs: {},
          sap: [],
        },
      }
    end

    test 'obtains host credentials successfully' do
      action = create_action(@action_class)
      assert_nil @credentials.scc_login
      assert_nil @credentials.scc_password
      auth_header = { Authorization: 'Token token=dummy-reg-token' }
      ::SccManager.expects(:post_scc_data).with(
        'https://scc.suse.com', '/connect/subscriptions/systems', auth_header,
        get_host_data(@host).to_json
      ).returns('{"login": "SCC_321321hasfdh1231", "password": "p3231ord"}')
      SccHostCredentials.expects(:find_or_create_by).returns(@credentials)
      planned_action = plan_action(action, get_host_data(@host), @host.id, 'dummy-reg-token')
      run_action planned_action
      assert_equal 'SCC_321321hasfdh1231', @host.scc_host_credentials.scc_login
      assert_equal 'p3231ord', @host.scc_host_credentials.scc_password
    end

    test 'fails if post request to scc fails' do
      action = create_action(@action_class)
      ::SccManager.expects(:post_scc_data).raises(RestClient::Exception)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('Could not connect to SUSE Customer Center: RestClient::Exception')
      planned_action = plan_action(action, get_host_data(@host), @host.id, 'dummy-reg=code')
      assert_raises StandardError do
        run_action planned_action
      end
    end

    test 'fails for invalid host id' do
      action = create_action(@action_class)
      ::SccManager.expects(:post_scc_data).returns('{"login": "SCC_321321hasfdh1231", "password": "p3231ord"}')
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with("Couldn't find Host::Managed with 'id'=24231 [WHERE \"hosts\".\"type\" = $1]")
      planned_action = plan_action(action, get_host_data(@host), 24_231, 'dummy-reg=code')
      assert_raises StandardError do
        run_action planned_action
      end
    end
  end
end
