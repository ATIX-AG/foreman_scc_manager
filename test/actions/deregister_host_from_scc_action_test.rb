require 'test_plugin_helper'

module ForemanSccManager
  class DeregisterHostFromSccActionTest < ActiveSupport::TestCase
    include Dynflow::Testing

    def setup
      @host = FactoryBot.create(:host, :with_scc_host_credentials)
      @credentials = @host.scc_host_credentials
      @action_class = ::Actions::SccManager::DeregisterHostFromScc
    end

    test 'run deregisters and finalize deletes credentials on success' do
      action = create_action(@action_class)
      scc_host_product = @host.scc_host_products.create!(
        scc_product: scc_products(:one),
        status: SccHostProduct::ACTIVE
      )
      SccHostCredentials.expects(:find_by!).with(id: @credentials.id).returns(@credentials)
      encoded_credentials = Base64.strict_encode64("#{@credentials.scc_login}:#{@credentials.scc_password}")
      auth_header = { Authorization: "Basic #{encoded_credentials}" }
      ::SccManager.expects(:delete_scc_data).with('https://scc.suse.com',
        '/connect/systems',
        auth_header)
      planned_action = plan_action(action, @credentials.id)
      run = run_action(planned_action)
      assert_not_empty SccHostCredentials.where(id: @credentials.id)
      finalize_action(run)
      assert_empty SccHostCredentials.where(id: @credentials.id)
      assert_empty SccHostProduct.where(id: scc_host_product.id)
    end

    test 'fails if delete request to scc fails' do
      action = create_action(@action_class)
      SccHostCredentials.stubs(:find_by!).returns(@credentials)
      ::SccManager.expects(:delete_scc_data).raises(RestClient::Exception)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('Could not connect to SUSE Customer Center: RestClient::Exception')
      assert_raises StandardError do
        run_action plan_action(action, @credentials.id)
      end
      assert_not_empty SccHostCredentials.where(id: @credentials.id)
    end
  end
end
