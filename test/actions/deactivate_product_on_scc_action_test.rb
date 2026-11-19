require 'test_plugin_helper'

module ForemanSccManager
  class DeactivateProductOnSccActionTest < ActiveSupport::TestCase
    include Dynflow::Testing

    def setup
      @host = FactoryBot.create(:host, :with_scc_host_credentials)
      @credentials = @host.scc_host_credentials
      @product = scc_products(:one)
      @scc_host_product = @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::ACTIVE)
      @product_data = { identifier: @product.suse_identifier, version: @product.version, arch: @product.arch }
      @action_class = ::Actions::SccManager::DeactivateProductOnScc
    end

    test 'run deactivates and finalize deletes the host product on success' do
      action = create_action(@action_class)
      encoded_credentials = Base64.strict_encode64("#{@credentials.scc_login}:#{@credentials.scc_password}")
      auth_header = { Authorization: "Basic #{encoded_credentials}" }
      ::SccManager.expects(:delete_scc_data).with('https://scc.suse.com',
        '/connect/systems/products',
        auth_header,
        @product_data.to_json)

      planned_action = plan_action(action, @credentials.id, @product_data, @scc_host_product.id)
      run = run_action(planned_action)
      assert_not_empty SccHostProduct.where(id: @scc_host_product.id)
      finalize_action(run)
      assert_empty SccHostProduct.where(id: @scc_host_product.id)
    end

    test 'fails if no scc credentials are found' do
      action = create_action(@action_class)
      SccHostCredentials.stubs(:find_by!).raises(ActiveRecord::RecordNotFound)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error)
      planned_action = plan_action(action, @credentials.id, @product_data, @scc_host_product.id)
      assert_raises StandardError do
        run_action(planned_action)
      end
    end

    test 'host product is kept if the scc deactivation fails' do
      action = create_action(@action_class)
      ::SccManager.expects(:delete_scc_data).raises(RestClient::Exception)
      ::Foreman::Logging.logger('foreman_scc_manager').expects(:error).with('Could not connect to SUSE Customer Center: RestClient::Exception')

      planned_action = plan_action(action, @credentials.id, @product_data, @scc_host_product.id)
      assert_raises StandardError do
        run_action(planned_action)
      end
      assert_not_empty SccHostProduct.where(id: @scc_host_product.id)
    end
  end
end
