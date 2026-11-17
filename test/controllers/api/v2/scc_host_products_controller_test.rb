require 'test_plugin_helper'

class Api::V2::SccHostProductsControllerTest < ActionController::TestCase
  def setup
    @host = FactoryBot.create(:host, :with_scc_host_credentials)
    @host_without_credentials = FactoryBot.create(:host)
    @scc_account = scc_accounts(:one)
    @scc_account.update!(organization: @host.organization)
    @product = scc_products(:one)
    @scc_account.scc_products << @product
  end

  test 'index returns empty results for a host with no activated products' do
    get :index, params: { scc_host_id: @host.id }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_empty body['results']
  end

  test 'index returns activated products for a host' do
    @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::ACTIVE)
    get :index, params: { scc_host_id: @host.id }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_equal 1, body['results'].count
    assert_equal @product.scc_id, body['results'].first['scc_id']
    assert_equal 'active', body['results'].first['status']
  end

  test 'create starts activation task and creates a pending product row' do
    ::ForemanTasks.expects(:async_task)
                  .with(::Actions::SccManager::ActivateProductOnScc, @host.scc_host_credentials.id, anything, anything)
                  .returns(ForemanTasks::Task::DynflowTask.new)

    assert_difference('@host.scc_host_products.count', 1) do
      post :create, params: { scc_host_id: @host.id, scc_id: @product.scc_id, reg_code: 'dummy-reg-code' }
    end
    assert_response :accepted
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('task_id')
  end

  test 'create fails when host has no scc credentials' do
    post :create, params: { scc_host_id: @host_without_credentials.id, scc_id: @product.scc_id, reg_code: 'dummy-reg-code' }
    assert_response :unprocessable_entity
  end

  test 'create fails with blank reg_code' do
    post :create, params: { scc_host_id: @host.id, scc_id: @product.scc_id, reg_code: '' }
    assert_response :unprocessable_entity
  end

  test 'create fails when product not found' do
    post :create, params: { scc_host_id: @host.id, scc_id: 0, reg_code: 'dummy-reg-code' }
    assert_response :not_found
  end

  test 'create refuses a product that is already registered' do
    @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::ACTIVE)
    ::ForemanTasks.expects(:async_task).never

    post :create, params: { scc_host_id: @host.id, scc_id: @product.scc_id, reg_code: 'dummy-reg-code' }
    assert_response :unprocessable_entity
    body = ActiveSupport::JSON.decode(@response.body)
    assert_equal 'This product is already registered on this host.', body['error']
  end

  test 'create retries a product whose registration failed' do
    scc_host_product = @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::FAILED)
    task = ForemanTasks::Task::DynflowTask.new(id: SecureRandom.uuid)
    ::ForemanTasks.expects(:async_task)
                  .with(::Actions::SccManager::ActivateProductOnScc, @host.scc_host_credentials.id, anything, scc_host_product.id)
                  .returns(task)

    assert_no_difference('@host.scc_host_products.count') do
      post :create, params: { scc_host_id: @host.id, scc_id: @product.scc_id, reg_code: 'dummy-reg-code' }
    end
    assert_response :accepted
    scc_host_product.reload
    assert_equal SccHostProduct::PENDING, scc_host_product.status
    assert_equal task.id, scc_host_product.task_id
  end

  test 'create does not find a product from another organization' do
    other_organization = FactoryBot.create(:organization)
    @scc_account.update!(organization: other_organization)

    post :create, params: { scc_host_id: @host.id, scc_id: @product.scc_id, reg_code: 'dummy-reg-code' }
    assert_response :not_found
  end

  test 'destroy starts deactivation task for an activated product' do
    scc_host_product = @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::ACTIVE)
    ::ForemanTasks.expects(:async_task)
                  .with(::Actions::SccManager::DeactivateProductOnScc, @host.scc_host_credentials.id, anything, scc_host_product.id)
                  .returns(ForemanTasks::Task::DynflowTask.new)

    delete :destroy, params: {
      scc_host_id: @host.id,
      id: @product.scc_id,
    }
    assert_response :accepted
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('task_id')
  end

  test 'destroy returns not_found for a nonexistent product' do
    delete :destroy, params: { scc_host_id: @host.id, id: 999_999 }  # no product with this id activated
    assert_response :not_found
  end

  test 'destroy fails when host has no credentials' do
    delete :destroy, params: { scc_host_id: @host_without_credentials.id, id: 1 }
    assert_response :unprocessable_entity
  end

  test 'destroy removes a failed activation locally without contacting SCC' do
    scc_host_product = @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::FAILED)
    ::ForemanTasks.expects(:async_task).never

    delete :destroy, params: { scc_host_id: @host.id, id: @product.scc_id }
    assert_response :success
    assert_empty SccHostProduct.where(id: scc_host_product.id)
  end

  test 'destroy refuses while the activation is still pending' do
    scc_host_product = @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::PENDING)
    ::ForemanTasks.expects(:async_task).never

    delete :destroy, params: { scc_host_id: @host.id, id: @product.scc_id }
    assert_response :unprocessable_entity
    assert SccHostProduct.exists?(scc_host_product.id)
  end

  test 'index returns empty results for an unregistered host with no facet' do
    get :index, params: { scc_host_id: @host_without_credentials.id }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_empty body['results']
  end

  test 'index filters products with search' do
    @host.scc_host_products.create!(scc_product: @product, status: SccHostProduct::ACTIVE)
    @host.scc_host_products.create!(scc_product: scc_products(:two), status: SccHostProduct::FAILED)

    get :index, params: { scc_host_id: @host.id, search: 'status = failed' }
    assert_response :success
    results = ActiveSupport::JSON.decode(@response.body)['results']
    assert_equal 1, results.count
    assert_equal 'failed', results.first['status']
  end
end
