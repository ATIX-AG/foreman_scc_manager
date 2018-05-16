class SccAccount < ApplicationRecord
  include Authorizable
  include Encryptable
  include ForemanTasks::Concerns::ActionSubject
  encrypts :password

  self.include_root_in_json = false

  belongs_to :organization
  belongs_to :sync_task, class_name: ForemanTasks::Task
  has_many :scc_products, dependent: :destroy
  has_many :scc_repositories, dependent: :destroy

  validates_lengths_from_database
  validates :name, presence: true
  validates :organization, presence: true
  validates :login, presence: true
  validates :password, presence: true
  validates :base_url, presence: true

  default_scope -> { order(:login) }

  scoped_search on: :login, complete_value: true

  def to_s
    name
  end

  def get_sync_status
    if sync_task.nil?
      return _('never synced')
    elsif sync_task.state == 'stopped'
      if sync_task.result == 'success'
        return synced
      else
        return sync_task.result
      end
    else
      return sync_task.state
    end
  end

  def test_connection
    SccManager.get_scc_data(base_url, '/connect/organizations/subscriptions', login, password)
    true
  rescue
    false
  end

  def update_scc_repositories(upstream_repositories)
    upstream_repo_ids = []
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
      upstream_repo_ids << ur['id']
    end
    # delete repositories beeing removed upstream (Active record seems to be wrong here...)
    # scc_repositories.where.not(scc_id: upstream_repo_ids).delete_all
    if upstream_repo_ids.empty?
      urid_query_fragment = ''
    else
      upstream_repo_ids_str = upstream_repo_ids.map{ |id| ActiveRecord::Base.connection.quote(id) }.join(',')
      urid_query_fragment = " and scc_repositories.scc_id not in (#{upstream_repo_ids_str})"
    end
    ActiveRecord::Base.connection.execute("delete from scc_repositories where scc_repositories.scc_account_id = #{ActiveRecord::Base.connection.quote(id)}#{urid_query_fragment};")
  end

  def update_scc_products(upstream_products)
    upstream_product_ids = []
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
      upstream_product_ids << up['id']
    end
    # delete products beeing removed upstream (Active record seems to be wrong here...)
    # scc_products.where.not(scc_id: upstream_product_ids).delete_all
    if upstream_product_ids.empty?
      upid_query_fragment = ''
    else
      upstream_product_ids_str = upstream_product_ids.map{ |id| ActiveRecord::Base.connection.quote(id) }.join(',')
      upid_query_fragment = " and scc_products.scc_id not in (#{upstream_product_ids_str})"
    end
    ActiveRecord::Base.connection.execute("delete from scc_products where scc_products.scc_account_id = #{ActiveRecord::Base.connection.quote(id)}#{upid_query_fragment};")
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
