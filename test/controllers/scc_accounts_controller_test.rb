require 'test_plugin_helper'

class SccAccountsControllerTest < ActionController::TestCase
  def setup
    # rubocop: disable Lint/SuppressedException
    begin
      ::Katello::ContentCredential
    rescue NameError
    end
    # rubocop: enable Lint/SuppressedException
    @scc_account = scc_accounts(:one)
  end

  def stub_custom_request(url, host = 'scc.example.com', auth = 'Basic b25ldXNlcjpvbmVwYXNz')
    stub_request(:get, url)
      .with(
        headers: {
          'Accept' => 'application/vnd.scc.suse.com.v4+json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => auth,
          'Host' => host,
          'User-Agent' => "rest-client/2.1.0 (linux-gnu x86_64) ruby/#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
        }
      )
      .to_return(status: 200, body: '', headers: {})
  end

  test 'should get new' do
    get :new, session: set_session_user
    assert_response :success
    assert_select 'title', 'Add SUSE Customer Center Account'
  end

  test 'should get edit' do
    get :edit, params: { :id => @scc_account.id }, session: set_session_user
    assert_response :success
    assert_select 'title', "Edit #{@scc_account.name}"
  end

  test 'should get index' do
    get :index, session: set_session_user
    assert_response :success
    assert_not_nil assigns(:scc_accounts)
    body = @response.body
    assert_not_empty body
    assert_select 'title', 'SUSE subscriptions'
  end

  test 'should show scc_account' do
    get :show, params: { :id => @scc_account.id }, session: set_session_user

    assert_not_nil assigns(:scc_account)
    assert_response :success
    assert_select 'title', "Product Selection for Account #{@scc_account.name}"
  end

  test 'should 404 for unknown scc_account' do
    get :show, params: { :id => 'does-not-exist' }, session: set_session_user

    assert_response :not_found
  end

  test 'should create scc_account' do
    account = scc_accounts(:two)
    organization = get_organization
    assert organization
    assert account
    assert_difference('SccAccount.count') do
      post :create, params:
                        { :scc_account => { :name => account.name, :login => account.login, :password => account.password, :organization_id => organization.id } },
                    session: set_session_user
    end
  end

  test 'should update scc_account' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :sync_date => Time.now, :interval => 'weekly' } }, session: set_session_user
    assert_redirected_to '/scc_accounts'
    assert_equal 'weekly', SccAccount.find(account.id).interval
  end

  test 'should update scc_account with empty date if interval not set' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :name => 'new_name', :sync_date => '', :interval => 'never' } }, session: set_session_user

    assert_equal 'new_name', SccAccount.find(account.id).name
  end

  test 'updates scc_account even if the date is invalid' do
    # @todo reminder to fix this in the future
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :name => 'new_name', :sync_date => 'invalid_date', :interval => 'never' } }, session: set_session_user

    assert_not_equal account.name, SccAccount.find(account.id).name
  end

  test 'should fail to update scc_account with interval set and empty date' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :sync_date => '', :interval => 'weekly' } }, session: set_session_user

    assert_equal SccAccount.find(account.id).sync_date, account.sync_date
  end

  test 'should fail to update scc_account with interval set and invalid date' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :sync_date => 'invalid_date', :interval => 'weekly' } }, session: set_session_user

    assert_equal SccAccount.find(account.id).sync_date, account.sync_date
  end

  test 'should fail to update scc_account with empty name' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :name => '', :sync_date => Time.now, :interval => 'weekly' } }, session: set_session_user

    assert_equal account.name, SccAccount.find(account.id).name
  end

  test 'should fail to update scc_account with empty login' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :login => '', :sync_date => Time.now, :interval => 'weekly' } }, session: set_session_user

    assert_equal account.login, SccAccount.find(account.id).login
  end

  test 'should fail to update scc_account with empty base url' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :base_url => '', :sync_date => Time.now, :interval => 'weekly' } }, session: set_session_user

    assert_equal account.base_url, SccAccount.find(account.id).base_url
  end

  test 'SCC server sync products' do
    stub_custom_request('https://scc.example.com/connect/organizations/products')
    stub_custom_request('https://scc.example.com/connect/organizations/repositories')

    account = scc_accounts(:one)
    assert account
    put :sync, params: { :id => account.id }, session: set_session_user
    assert_redirected_to '/scc_accounts'
  end

  test 'SCC server bulk subscribe products' do
    stub_custom_request('https://scc.example.com/connect/organizations/repositories')

    account = scc_accounts(:one)
    product1 = scc_products(:one)
    product2 = scc_products(:two)
    account.scc_products = [product1, product2]
    put :bulk_subscribe, params: { :id => account.id, :scc_account => { :scc_subscribe_product_ids => [product1.id, product2.id] } }, session: set_session_user

    assert_redirected_to '/scc_accounts'
  end

  test 'should delete scc_account' do
    account = scc_accounts(:two)
    assert_difference 'SccAccount.count', -1 do
      delete :destroy, params: { :id => account.id }, session: set_session_user
    end
  end
end
