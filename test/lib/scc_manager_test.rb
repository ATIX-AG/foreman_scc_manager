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
  end
end
