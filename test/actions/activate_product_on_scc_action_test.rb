require 'test_plugin_helper'

module ForemanSccManager
  class ActivateProductOnSccActionTest < ActiveSupport::TestCase
    include Dynflow::Testing

    def setup
      @product_data = { identifier: 'SLES', arch: 'x86_64', version: 12, token: 'dummy-reg-token' }
      @host = FactoryBot.create(:host, :with_scc_host_credentials)
      @credentials = @host.scc_host_credentials
      @action_class = ::Actions::SccManager::ActivateProductOnScc
    end

    test 'run product activation action' do
      action = create_action(@action_class)
      SccHostCredentials.expects(:find_by!).with(id: @credentials.id).returns(@credentials)
      encoded_credentials = Base64.strict_encode64("#{@credentials.scc_login}:#{@credentials.scc_password}")
      auth_header = { Authorization: "Basic #{encoded_credentials}" }
      ::SccManager.expects(:post_scc_data).with('https://scc.suse.com',
        '/connect/systems/products',
        auth_header,
        @product_data.to_json)
      planned_action = plan_action(action, @credentials.id, @product_data)
      run_action planned_action
    end

    test 'fail if no scc credentials are found' do
      action = create_action(@action_class)
      planned_action = plan_action(action, @credentials.id, @product_data)
      SccHostCredentials.stubs(:find_by!).raises(ActiveRecord::RecordNotFound)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('There are no SCC credentials available for the host. Product cannot be activated: ActiveRecord::RecordNotFound')
      assert_raises StandardError do
        run_action planned_action
      end
    end

    test 'fails if post request to scc fails' do
      action = create_action(@action_class)
      SccHostCredentials.stubs(:find_by!).returns(@credentials)
      ::SccManager.expects(:post_scc_data).raises(RestClient::Exception)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('Could not connect to SCC portal: RestClient::Exception')
      planned_action = plan_action(action, @credentials.id, @product_data)
      assert_raises StandardError do
        run_action planned_action
      end
    end

    test 'finalize sets status to active on success' do
      scc_product = scc_products(:one)
      scc_host_product = @host.scc_host_products.create!(scc_product: scc_product, status: SccHostProduct::PENDING)

      action = create_action(@action_class)
      SccHostCredentials.stubs(:find_by!).returns(@credentials)
      ::SccManager.stubs(:post_scc_data).returns('{}')

      planned_action = plan_action(action, @credentials.id, @product_data, scc_host_product.id)
      run = run_action planned_action
      finalize_action run

      assert_equal SccHostProduct::ACTIVE, scc_host_product.reload.status
    end

    test 'sets status to failed when scc call fails' do
      scc_product = SccProduct.where.not(product_id: nil).first || scc_products(:one)
      scc_host_product = @host.scc_host_products.create!(scc_product: scc_product, status: SccHostProduct::PENDING)

      action = create_action(@action_class)
      SccHostCredentials.stubs(:find_by!).returns(@credentials)
      ::SccManager.expects(:post_scc_data).raises(RestClient::Exception)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('Could not connect to SCC portal: RestClient::Exception')

      planned_action = plan_action(action, @credentials.id, @product_data, scc_host_product.id)
      assert_raises StandardError do
        run_action planned_action
      end

      assert_equal SccHostProduct::FAILED, scc_host_product.reload.status
    end
  end
end
