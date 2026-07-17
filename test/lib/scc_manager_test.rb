require 'test_plugin_helper'

class SccManagerTest < ActiveSupport::TestCase
  def setup
    @dummy_base_url = 'https://scc.example.com'
    @dummy_path = '/connect/organizations/subscriptions'
    @dummy_login = 'oneuser'
    @dummy_password = 'onepass'
    @default_headers = { headers: {
      Accept: 'application/vnd.scc.suse.com.v4+json',
      Authorization: 'Basic b25ldXNlcjpvbmVwYXNz',
    } }
  end

  context 'SCC get request' do
    test 'validate single response' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(@default_headers)
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
        .with(@default_headers)
        .to_return(status: 200,
          body: '[{ "foo": "bar" }]',
          headers: { link: '<https://scc.example.com/second/addr>; rel="next"' })

      stub_request(:get, "#{@dummy_base_url}/second/addr")
        .with(@default_headers)
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

    test 'fail when SCC service unavailable' do
      stub_request(:get, "#{@dummy_base_url}#{@dummy_path}")
        .with(@default_headers)
        .to_return(status: 404, body: '', headers: {})

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
        .with(@default_headers)
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
end
