module SccManager
  # adapted from https://github.com/SUSE/connect
  def self.get_scc_data(base_url, rest_url, login, password)
    if SETTINGS[:katello][:cdn_proxy] && SETTINGS[:katello][:cdn_proxy][:host]
      proxy_config = SETTINGS[:katello][:cdn_proxy]
      uri = URI('')

      uri.scheme = URI.parse(proxy_config[:host]).scheme
      uri.host = URI.parse(proxy_config[:host]).host
      uri.port = proxy_config[:port].try(:to_s)
      uri.user = proxy_config[:user].try(:to_s)
      uri.password = proxy_config[:password].try(:to_s)

      RestClient.proxy = uri.to_s
    end

    url = base_url + rest_url
    auth_header = { Authorization: 'Basic ' + Base64.encode64("#{login}:#{password}").chomp,
                    Accept: 'application/vnd.scc.suse.com.v4+json' }
    results = []
    loop do
      response = RestClient.get url, auth_header
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
