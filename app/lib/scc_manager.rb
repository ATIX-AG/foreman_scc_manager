module SccManager
  REST_TIMEOUT = 180
  # adapted from https://github.com/SUSE/connect
  def self.build_host_payload(host)
    {
      hostname: host.name,
      hwinfo: {
        uuid: host.uuid,
        cpus: nil,
        vcpus: nil,
        sockets: nil,
        mem_total: nil,
        arch: host&.architecture&.name,
        hypervisor: host&.compute_resource&.type&.delete_prefix('Foreman::Model::'),
        cloud_provider: '',
        container_runtime: nil,
        uname: '',
        nodes: nil,
        clusters: nil,
        server_url: '',
        arch_specs: {},
        sap: [],
      },
    }
  end

  def self.get_scc_data(base_url, rest_url, login, password)
    RestClient.proxy = ::HttpProxy.default_global_content_proxy.full_url if ::HttpProxy.default_global_content_proxy

    url = base_url + rest_url
    credentials = Base64.strict_encode64("#{login}:#{password}").chomp
    auth_header = { Authorization: "Basic #{credentials}",
                    Accept: 'application/vnd.scc.suse.com.v4+json' }
    results = []
    loop do
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        timeout: REST_TIMEOUT,
        headers: auth_header
      )
      raise 'Connection to SUSE costomer center failed.' unless response.code == 200

      links = (response.headers[:link] || '').split(', ').map do |link|
        href, rel = /<(.*?)>; rel="(\w+)"/.match(link).captures
        [rel.to_sym, href]
      end
      links = Hash[*links.flatten]
      results += JSON.parse response
      url = links[:next]
      break unless url
    end
    results
  ensure
    RestClient.proxy = ''
  end

  def self.post_scc_data(base_url, rest_url, auth_header, payload)
    RestClient.proxy = ::HttpProxy.default_global_content_proxy.full_url if ::HttpProxy.default_global_content_proxy

    url = base_url + rest_url
    header = {
      Accept: 'application/vnd.scc.suse.com.v4+json',
      content_type: 'application/json',
    }
    RestClient.post url, payload, header.merge(auth_header)
  rescue RestClient::Exception => e
    raise "Something went wrong while connecting to the SCC: #{e.message}" unless e.response

    raise "Something went wrong while connecting to the SCC: Return code: #{e.response.code}, Error: #{JSON.parse(e.response.body)['error']}"
  ensure
    RestClient.proxy = ''
  end

  def self.delete_scc_data(base_url, rest_url, auth_header, payload = nil)
    RestClient.proxy = ::HttpProxy.default_global_content_proxy.full_url if ::HttpProxy.default_global_content_proxy
    url = base_url + rest_url
    header = {
      Accept: 'application/vnd.scc.suse.com.v4+json',
      content_type: 'application/json',
    }
    RestClient::Request.execute(
      method: :delete,
      url: url,
      headers: header.merge(auth_header),
      payload: payload
    )
  rescue RestClient::Exception => e
    raise "Something went wrong while connecting to the SCC: Return code: #{e.response.code}, Error: #{JSON.parse(e.response.body)['error']}"
  ensure
    RestClient.proxy = ''
  end

  # Cope for the very weird structure of SCC output
  def self.sanitize_products(products, result = {})
    products.reduce(result) do |res, product|
      sanitize_products(product['extensions'].tap do |extensions|
        product['extensions'] = extensions.map { |extension| { 'id' => extension['id'] } }
        res[product['id']] = product.merge(result.fetch(product['id'], {}))
        res[product['id']]['extensions'] |= product['extensions']
      end, res)
    end
  end
end
