# frozen_string_literal: true

module SccManager
  # adapted from https://github.com/SUSE/connect
  def self.get_scc_data(base_url, rest_url, login, password)
    if (proxy_config = ::HttpProxy.default_global_content_proxy)
      uri = URI(proxy_config[:url])
      uri.user = proxy_config[:username]
      uri.password = proxy_config[:password] if uri.user.present?

      RestClient.proxy = uri.to_s
    end

    url = base_url + rest_url
    auth_header = { Authorization: "Basic #{Base64.encode64("#{login}:#{password}").chomp}",
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
