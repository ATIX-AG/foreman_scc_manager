#require 'rest-client'
#require 'json'
#require 'base64'

class SccAccount < ActiveRecord::Base
  include Authorizable

  self.include_root_in_json = false

  belongs_to :organization
  has_many :scc_products, dependent: :destroy
  has_many :scc_repositories, dependent: :destroy

  validates_lengths_from_database
  validates :organization, presence: true

  default_scope -> {order(:login)}

  scoped_search on: :login, complete_value: true

  def to_s
    'SUSE customer center account ' + login
  end

  # adapted from https://github.com/SUSE/connect
  def get_scc_data(rest_url)
    url = base_url + rest_url
    auth_header = { Authorization: 'Basic ' + Base64.encode64("#{login}:#{password}").chomp }
    results = []
    loop do
      response = RestClient.get url, auth_header
      raise "Connection to SUSE costomer center failed." unless response.code == 200
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

  def get_scc_upstream_repositories
    get_scc_data '/connect/organizations/repositories'
  end

  def get_scc_upstream_products
    get_scc_data '/connect/organizations/products'
  end

  def sync_scc_products
    new_records = 0
    updated_records = 0
    deleted_records = 0
    upstream_ids = []
    upstream_repositories = get_scc_upstream_repositories
    upstream_products = get_scc_upstream_products
    SccProduct.transaction do
      # import repositories
      upstream_repositories.each do |ur|
        cached_repository = scc_repositories.find_or_initialize_by(scc_id: ur['id'])
        cached_repository.name = ur['name']
        cached_repository.distro_target = ur['distro_target']
        cached_repository.description = ur['description']
        cached_repository.url, cached_repository.token = ur['url'].split('?')
        cached_repository.enabled = ur['enabled']
        cached_repository.autorefresh = ur['autorefresh']
        cached_repository.installer_updates = ur['installer_updates']
        cached_repository.save!
      end
      # import products
      upstream_products.each do |up|
        cached_product = scc_products.find_or_initialize_by(scc_id: up['id'])
        cached_product.name = up['name']
        cached_product.version = up['version']
        cached_product.arch = up['arch']
        cached_product.description = up['description']
        cached_product.friendly_name = up['friendly_name']
        cached_product.product_type = up['product_type']
        cached_product.scc_repositories = scc_repositories.where(scc_id: up['repositories'].map { |repo| repo['id'] })
        new_records += 1 if cached_product.new_record?
        updated_records += 1 if cached_product.changed? and not cached_product.new_record?
        cached_product.save!
        upstream_ids << cached_product.id
      end
      # delete products beeing removed upstream
      deleted_records = scc_products.where(id: scc_product_ids - upstream_ids).destroy_all.count
      # rewire product to product relationships
      upstream_products.each do |up|
        extensions = scc_products.where(scc_id: up['extensions'].map { |ext| ext['id'] })
        scc_products.find_by!(scc_id: up['id']).update!(scc_extensions: extensions)
      end
    end
    self.synced = DateTime.now
    save!
    return new_records, updated_records, deleted_records
  end

end
