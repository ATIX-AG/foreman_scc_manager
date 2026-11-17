require 'test_plugin_helper'

class SccManagerTest < ActiveSupport::TestCase
  def common_setup
    @dummy_base_url = 'https://scc.example.com'
    @default_headers = {
      Accept: 'application/vnd.scc.suse.com.v4+json',
      Authorization: 'Basic b25ldXNlcjpvbmVwYXNz',
    }
  end

  context 'SCC get request' do
    def setup
      common_setup
      @dummy_path = '/connect/organizations/subscriptions'
      @dummy_login = 'oneuser'
      @dummy_password = 'onepass'
    end

    test 'validate single response' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @default_headers)
        .to_return(status: 200,
          body: '[{ "foo": "bar" }]',
          headers: {})

      results = ::SccManager.get_scc_data(@dummy_base_url,
        @dummy_path,
        @dummy_login,
        @dummy_password)
      assert_equal results[0]['foo'], 'bar'
    end
    test 'follow multiple links' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @default_headers)
        .to_return(status: 200,
          body: '[{ "foo": "bar" }]',
          headers: { link: '<https://scc.example.com/second/addr>; rel="next"' })

      stub_request(:get, "#{@dummy_base_url}/second/addr")
        .with(headers: @default_headers)
        .to_return(status: 200,
          body: '[{ "foo2": "bar2" }]',
          headers: {})

      results = ::SccManager.get_scc_data(@dummy_base_url,
        @dummy_path,
        @dummy_login,
        @dummy_password)
      assert_equal results[0]['foo'], 'bar'
      assert_equal results[1]['foo2'], 'bar2'
    end

    test 'fail due to client error' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @default_headers)
        .to_return(status: 404, body: '{ "error": "some client error description" }')

      assert_raises RuntimeError do
        ::SccManager.get_scc_data(@dummy_base_url,
          @dummy_path,
          @dummy_login,
          @dummy_password)
      end
    end

    test 'fail due to server error' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @default_headers)
        .to_return(status: 501, body: '{ "error": "some server error description" }')

      assert_raises RuntimeError do
        ::SccManager.get_scc_data(@dummy_base_url,
          @dummy_path,
          @dummy_login,
          @dummy_password)
      end
    end

    test 'uses HTTP-Proxy' do
      ::HttpProxy.any_instance.stubs(:encryption_key).returns('25d224dd383e92a7e0c82b8bf7c985e8')
      proxy = FactoryBot.build(:http_proxy)
      proxy.username = 'dummy'
      proxy.password = 'secret'
      proxy.save!
      default_global_proxy_backup = Setting[:content_default_http_proxy]
      Setting[:content_default_http_proxy] = proxy.name

      # ensure password is saved encrypted and decrypted before use
      assert_not_equal 'secret', proxy[:password]
      assert_include proxy.full_url, 'secret'
      RestClient.expects(:proxy=).with(proxy.full_url)
      RestClient.expects(:proxy=).with('')
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @default_headers)
        .to_return(status: 200,
          body: '[{ "foo": "bar" }]',
          headers: {})

      results = ::SccManager.get_scc_data(@dummy_base_url,
        @dummy_path,
        @dummy_login,
        @dummy_password)
      assert_equal results[0]['foo'], 'bar'

      Setting[:content_default_http_proxy] = default_global_proxy_backup
    end
  end

  context 'SCC post request' do
    def setup
      common_setup
      @dummy_path = '/connect/subscriptions/systems'
      @dummy_auth_header = { Authorization: 'Token token=A3FOO21FVXTABAR' }
      @dummy_host_data = {
        hostname: 'some_host_name.local',
        hwinfo: {
          uuid: 'sdf-sadf-1231-sadf',
          arch: 'x86_64',
          hypervisor: 'Vmware',
        },
      }.to_json
      @headers_with_token = @default_headers
      @headers_with_token[:Authorization] = @dummy_auth_header[:Authorization]
    end

    test 'valid request' do
      stub_request(:post, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @headers_with_token)
        .to_return(status: 201,
          body: '{ "id": 3212, "login": "SCC_321321hasfdh1231", "password": "p3231ord" }',
          headers: {})

      results = ::SccManager.post_scc_data(@dummy_base_url,
        @dummy_path,
        @dummy_auth_header,
        @dummy_host_data)
      assert_equal results.code, 201
    end

    test 'fail due to client error' do
      stub_request(:post, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @headers_with_token)
        .to_return(body: '{ "error": "some client error description" }', status: 404)
        .to_raise(RestClient::NotFound)

      assert_raises RuntimeError do
        ::SccManager.post_scc_data(@dummy_base_url,
          @dummy_path,
          @dummy_auth_header,
          @dummy_host_data)
      end
    end

    test 'fail due to server error' do
      stub_request(:post, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @headers_with_token)
        .to_return(body: '{ "error": "some server error description" }', status: 501)
        .to_raise(RestClient::InternalServerError)

      assert_raises RuntimeError do
        ::SccManager.post_scc_data(@dummy_base_url,
          @dummy_path,
          @dummy_auth_header,
          @dummy_host_data)
      end
    end
  end

  context 'SCC post activate product request' do
    def setup
      common_setup
      @dummy_path = '/connect/systems/products'
      @dummy_auth_header = { Authorization: 'Token token=A3FOO21FVXTABAR' }
      @dummy_host_data = {
        hostname: 'some_host_name.local',
        hwinfo: {
          uuid: 'sdf-sadf-1231-sadf',
          arch: 'x86_64',
          hypervisor: 'Vmware',
        },
      }.to_json
      @headers_with_token = @default_headers
      @headers_with_token[:Authorization] = @dummy_auth_header[:Authorization]
    end

    test 'valid request' do
      stub_request(:post, "#{@dummy_base_url}#{@dummy_path}")
        .with(headers: @headers_with_token)
        .to_return(status: 200,
          body: '[{ "foo": "bar" }]',
          headers: {})

      ::SccManager.post_scc_data(@dummy_base_url,
        @dummy_path,
        @dummy_auth_header,
        @dummy_host_data)
    end
  end
end
