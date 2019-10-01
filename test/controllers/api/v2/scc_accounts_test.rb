require 'test_plugin_helper'

class Api::V2::SccAccountsControllerTest < ActionController::TestCase
  def setup
    @scc_account = scc_accounts(:one)

    # test_connection:
    stub_request(:get, 'https://scc.example.com/connect/organizations/subscriptions')
      .with(
        headers: {
          'Accept' => 'application/vnd.scc.suse.com.v4+json',
          'Authorization' => 'Basic b25ldXNlcjpvbmVwYXNz',
          'Host' => 'scc.example.com'
        }
      ).to_return(
        status: 200,
        body: File.read("#{File.dirname(__FILE__)}/data_subscriptions.json"),
        headers: {
          server: 'nginx',
          date: 'Tue, 05 Mar 2019 15:07:38 GMT',
          content_type: 'application/json; charset=utf-8',
          transfer_encoding: 'chunked',
          connection: 'keep-alive',
          vary: 'Accept-Encoding',
          x_frame_options: 'SAMEORIGIN',
          x_xss_protection: '1; mode=block',
          x_content_type_options: 'nosniff',
          per_page: '10',
          total: '3',
          scc_api_version: 'v4',
          etag: 'W/"0123456789abcdef0123456789abcdef"',
          cache_control: 'max-age=0, private, must-revalidate',
          set_cookie: [
            'XSRF-TOKEN=TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBp%0Ac2NpbmcgZWxpdCwgc2VkIGRvIGVpdXNtb2QgdGVtcG9yIGluY2l; path=/; secure',
            'Uy#u~osh#oh3ahv.op0OII; Expires=Fri, 02-Mar-2029 15:07:20 GMT; Path=/'
          ],
          x_request_id: '67450237-e4aa-4994-a47d-ed3ce142555b',
          x_runtime: '0.144083',
          strict_transport_security: 'max-age=15552000, max-age=300',
          content_encoding: 'gzip'
        }
      )
    ############
    # Repositories #
    ############
    stub_request(:get, 'https://scc.example.com/connect/organizations/repositories')
      .with(
        headers: {
          'Accept' => 'application/vnd.scc.suse.com.v4+json',
          'Authorization' => 'Basic b25ldXNlcjpvbmVwYXNz',
          'Host' => 'scc.example.com'
        }
      ).to_return(
        status: 200,
        body: File.read("#{File.dirname(__FILE__)}/data_repositories.json"),
        headers: {
          server: 'nginx',
          date: 'Mon, 07 Oct 2019 13:14:31 GMT',
          content_type: 'application/json; charset=utf-8',
          transfer_encoding: 'chunked',
          connection: 'keep-alive',
          vary: 'Accept-Encoding',
          x_frame_options: 'SAMEORIGIN',
          x_xss_protection: '1; mode=block',
          x_content_type_options: 'nosniff',
          per_page: '50',
          total: '3',
          scc_api_version: 'v4',
          etag: 'W/"73c45129512441a82f6b0752e53ed1c5"',
          cache_control: 'max-age=0, private, must-revalidate',
          set_cookie: [
            'XSRF-TOKEN=SEZSwgerzOHlW5vYxxcVxrRQ3J4lKMmwGAIXpDyuTyCtcgQqrkMDlSdlxhU6rQp71%2Fdic6jiKgVbJB6vCeAJ2A%3D%3D; path=/; secure',
            'TbBx+jfg=v1XitvAA@@ncY; Expires=Thu, 04-Oct-2029 13:14:57 GMT; Path=/'
          ],
          x_request_id: '2418bd69-efab-4d78-9a73-63570744d2cb',
          x_runtime: '0.645444',
          strict_transport_security: 'max-age=15552000, max-age=300',
          content_encoding: 'gzip'
        }
      )
    ############
    # Products #
    ############
    # products page1
    stub_request(:get, 'https://scc.example.com/connect/organizations/products')
      .with(
        headers: {
          'Accept' => 'application/vnd.scc.suse.com.v4+json',
          'Authorization' => 'Basic b25ldXNlcjpvbmVwYXNz',
          'Host' => 'scc.example.com'
        }
      ).to_return(
        status: 200,
        body: File.read("#{File.dirname(__FILE__)}/data_products_page1.json"),
        headers: {
          server: 'nginx',
          date: 'Mon, 11 Mar 2019 15:37:00 GMT',
          content_type: 'application/json; charset=utf-8',
          transfer_encoding: 'chunked',
          connection: 'keep-alive',
          vary: 'Accept-Encoding',
          x_frame_options: 'SAMEORIGIN',
          x_xss_protection: '1; mode=block',
          x_content_type_options: 'nosniff',
          link: '<https://scc.example.com/connect/organizations/products?page=2>; rel="last", <https://scc.example.com/connect/organizations/products?page=2>; rel="next"',
          per_page: 25,
          total: 50,
          scc_api_version: 'v4',
          etag: '57fbfddfb5cc165b2581d297cad27a53',
          cache_control: 'max-age=0, private, must-revalidate',
          set_cookie: [
            'XSRF-TOKEN=EABKsiefcpa7dMNEXRixmihKeUfIvXF4AwmNQt2wZG5Fm%2FPKvR0%2FMBDVV5lZJ3p4waUAcds2xWv42vbKg9GQhg%3D%3D; path=/; secure',
            'TbBx+jfg=v1jitvAA@@UII; Expires=Thu, 08-Mar-2029 15:37:15 GMT; Path=/'
          ],
          x_request_id: 'd2797941-1aed-499c-8e06-b4cb52515443',
          x_runtime: '6.671012',
          strict_transport_security: 'max-age=15552000, max-age=300',
          content_encoding: 'gzip'
        }
      )
    # products page2
    stub_request(:get, 'https://scc.example.com/connect/organizations/products?page=2')
      .with(
        headers: {
          'Accept' => 'application/vnd.scc.suse.com.v4+json',
          'Authorization' => 'Basic b25ldXNlcjpvbmVwYXNz',
          'Host' => 'scc.example.com'
        }
      ).to_return(
        status: 200,
        body: File.read("#{File.dirname(__FILE__)}/data_products_page2.json"),
        headers: {
          server: 'nginx',
          date: 'Mon, 11 Mar 2019 15:37:19 GMT',
          content_type: 'application/json; charset=utf-8',
          transfer_encoding: 'chunked',
          connection: 'keep-alive',
          vary: 'Accept-Encoding',
          x_frame_options: 'SAMEORIGIN',
          x_xss_protection: '1; mode=block',
          x_content_type_options: 'nosniff',
          link: '<https://scc.example.com/connect/organizations/products?page=1>; rel="first", <https://scc.example.com/connect/organizations/products?page=1>; rel="prev"',
          per_page: 3,
          total: 2,
          scc_api_version: 'v4',
          etag: '3fb638e3ab553dc6c88ef9914540b4bd',
          cache_control: 'max-age=0, private, must-revalidate',
          set_cookie: [
            'XSRF-TOKEN=z3bGc45lQxf%2FXq7qN7cwzJrK1zcw4e7uuskVCPejeN0zv3ExUcb8ev3jhGnDGJaSz3ZwV7Dk0SdLII%2FOcI2eEw%3D%3D; path=/; secure',
            'TbBx+jfg=v1oytvAA@@I73; Expires=Thu, 08-Mar-2029 15:37:23 GMT; Path=/'
          ],
          x_request_id: '17e6707a-1134-403d-a49c-7344442446c1',
          x_runtime: '6.671012',
          strict_transport_security: 'max-age=15552000, max-age=300',
          content_encoding: 'gzip'
        }
      )
  end

  test 'should get index' do
    get :index, params: {}
    assert_response :success
    assert_not_nil assigns(:scc_accounts)
    body = ActiveSupport::JSON.decode(@response.body)
    assert_not_empty body
    assert_not_empty body['results']
  end

  test 'should show scc_account' do
    get :show, params: { :id => @scc_account.id }
    assert_not_nil assigns(:scc_account)
    assert_response :success
  end

  test 'should 404 for unknown scc_account' do
    get :show, params: { :id => 'does-not-exist' }
    assert_response :not_found
  end

  test 'should create scc_account' do
    account = scc_accounts(:two)
    organization = get_organization
    assert organization
    assert account
    post :create, params: { :name => account.name, :login => account.login, :password => account.password, :organization_id => organization.id }
    assert_response :created
  end

  test 'should refuse create scc_account' do
    account = scc_accounts(:two)
    account.login = nil
    assert_nil account.login
    organization = get_organization
    assert organization
    post :create, params: { :name => account.name, :password => account.password, :login => account.login, :organization_id => organization.id }
    assert_equal response.status, 500
  end

  test 'should update scc_account' do
    account = scc_accounts(:two)
    put :update, params: { id: account.id, :scc_account => { :interval => 'weekly' } }
    assert_equal 'weekly', assigns(:scc_account).interval
  end

  test 'SCC server connection-test' do
    account = scc_accounts(:one)
    assert account
    put :test_connection, params: { :scc_account => { :login => account.login, :password => account.password, :base_url => account.base_url } }
    assert_response :ok
  end

  test 'SCC server sync products new' do
    scc_account = scc_accounts(:one)
    assert scc_account
    put :sync, params: { :id => scc_account.id }
    assert_response :ok
  end

  test 'SCC server bulk subscribe products' do
    account = scc_accounts(:one)
    product1 = scc_products(:one)
    product2 = scc_products(:two)
    account.scc_products = [product1, product2]
    put :bulk_subscribe, params: { :id => account.id, :scc_subscribe_product_ids => [product1.id, product2.id] }
    assert_response :ok
  end

  test 'SCC server bulk subscribe products fails' do
    account = scc_accounts(:one)
    product1 = scc_products(:one)
    product2 = scc_products(:two)
    account.scc_products = [product1, product2]
    put :bulk_subscribe, params: { :id => account.id, :scc_subscribe_product_ids => [] }
    assert_response :expectation_failed
    assert_match response.body, '"No Product selected"'
  end

  test 'should delete scc_account' do
    scc_account = scc_accounts(:two)
    assert_difference 'SccAccount.count', -1 do
      delete :destroy, params: { :id => scc_account.id }
    end
    assert_response :ok
  end
end
