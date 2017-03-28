module SccManager
  # adapted from https://github.com/SUSE/connect
  def self.get_scc_data(base_url, rest_url, login, password)
    url = base_url + rest_url
    auth_header = { Authorization: 'Basic ' + Base64.encode64("#{login}:#{password}").chomp }
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
  end
end
