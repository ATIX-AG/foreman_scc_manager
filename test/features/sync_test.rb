require 'test_plugin_helper'

class SccAccountSyncTest < ActiveSupport::TestCase
  # rubocop:disable Metrics/MethodLength
  def setup
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
        body: fixture_file_upload('data_subscriptions.json').read,
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
        body: fixture_file_upload('data_products_page1.json').read,
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
        body: fixture_file_upload('data_products_page1.json').read,
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
  # rubocop:enable Metrics/MethodLength

  test 'SCC server connection-test' do
    assert scc_accounts(:one).test_connection
  end

  test 'SCC server sync products new' do
    scc_account = scc_accounts(:one)
    assert scc_account
    products = ::SccManager.get_scc_data(
      scc_account.base_url,
      '/connect/organizations/products',
      scc_account.login,
      scc_account.password
    )
    assert_not_nil(products)
    assert_equal(50, products.length)
  end
end
