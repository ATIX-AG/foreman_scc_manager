class SccAccount < ActiveRecord::Base
  include Authorizable
  include Encryptable
  include ForemanTasks::Concerns::ActionSubject
  encrypts :password

  SYNC_STATI = [nil, 'running', 'successful', 'failed'].freeze

  self.include_root_in_json = false

  belongs_to :organization
  has_many :scc_products, dependent: :destroy
  has_many :scc_repositories, dependent: :destroy

  validates_lengths_from_database
  validates :name, presence: true
  validates :organization, presence: true
  validates :login, presence: true
  validates :password, presence: true
  validates :base_url, presence: true
  validates :sync_status, inclusion: { in: SYNC_STATI }

  default_scope -> { order(:login) }

  scoped_search on: :login, complete_value: true

  def to_s
    name
  end

  def get_sync_status
    if sync_status.nil?
      return _('never synced')
    elsif sync_status == 'running'
      return _('sync in progress')
    elsif sync_status == 'successful'
      return synced
    elsif sync_status == 'failed'
      return _('last sync failed')
    end
    ''
  end

  def test_connection
    SccManager.get_scc_data(base_url, '/connect/organizations/subscriptions', login, password)
    true
  rescue
    false
  end

  def update_scc_repositories(upstream_repositories)
    upstream_repo_ids = []
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
        upstream_repo_ids << cached_repository.id
      end
      # delete repositories beeing removed upstream
      scc_repositories.where(id: scc_repository_ids - upstream_repo_ids).destroy_all.count
    end
  end

  def update_scc_products(upstream_products)
    upstream_product_ids = []
    SccProduct.transaction do
      # import products
      upstream_products.each do |up|
        cached_product = scc_products.find_or_initialize_by(scc_id: up['id'])
        cached_product.name = up['name']
        cached_product.version = up['version']
        cached_product.arch = up['arch']
        cached_product.description = up['description']
        cached_product.friendly_name = up['friendly_name']
        cached_product.product_type = up['product_type']
        cached_product.scc_repositories =
          scc_repositories.where(scc_id: up['repositories'].map { |repo| repo['id'] })
        cached_product.save!
        upstream_product_ids << cached_product.id
      end
      # delete products beeing removed upstream
      scc_products.where(id: scc_product_ids - upstream_product_ids).destroy_all.count
      # rewire product to product relationships
      upstream_products.each do |up|
        extensions = scc_products.where(scc_id: up['extensions'].map { |ext| ext['id'] })
        begin
          scc_products.find_by!(scc_id: up['id']).update!(scc_extensions: extensions)
        rescue ActiveRecord::RecordNotFound
          logger.info "Failed to find parent scc_product '#{up['name']}'."
        end
      end
    end
  end
end
