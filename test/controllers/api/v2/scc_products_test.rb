require 'test_plugin_helper'

class Api::V2::SccProductsControllerTest < ActionController::TestCase
  def setup
    @scc_account = scc_accounts(:one)
    @scc_product1 = scc_products(:one)
    @scc_product2 = scc_products(:two)
    @scc_product3 = scc_products(:three)
    @scc_product4 = scc_products(:four)
    @scc_account.scc_products = [@scc_product1, @scc_product2, @scc_product3, @scc_product4]
  end

  test 'should get index' do
    get :index, params: { :scc_account_id => @scc_account.id }
    assert_response :success
    assert_not_nil assigns(:scc_products)
    body = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty body
    assert_not_empty body['results']
  end

  test 'should show scc_product' do
    get :show, params: { :id => @scc_product1.id, :scc_account_id => @scc_account.id }
    assert_not_nil assigns(:scc_product)
    assert_response :success
  end

  test 'should 404 for unknown scc_product' do
    get :show, params: { :id => 'does-not-exist', :scc_account_id => @scc_account.id }
    assert_response :not_found
  end

  test 'SCC server subscribe product' do
    put :subscribe, params: { :id => @scc_product1.id, :scc_account_id => @scc_account.id }
    assert_response :ok
  end

  test 'SCC server subscribe product not found' do
    put :subscribe, params: { :id => 'doest-not-exit', :scc_account_id => @scc_account.id }
    assert_response :not_found
  end

  test 'show subscribed products only' do
    get :index, params: { :scc_account_id => @scc_account.id, :subscribed_only => true }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty body
    assert_equal 2, body['results'].count
    assert_equal 2, body['subtotal']
  end

  test 'show all products if subscribed_only flag is set to false' do
    get :index, params: { :scc_account_id => @scc_account.id, :subscribed_only => false }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty body
    assert_equal 4, body['results'].count
    assert_equal 4, body['subtotal']
  end
end
