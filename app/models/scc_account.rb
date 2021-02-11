class SccAccount < ApplicationRecord
  include Authorizable
  include Encryptable
  include ForemanTasks::Concerns::ActionSubject

  attr_accessor :scc_products_with_repos_count

  encrypts :password

  NEVER = 'never'.freeze
  DAILY = 'daily'.freeze
  WEEKLY = 'weekly'.freeze
  MONTHLY = 'monthly'.freeze
  TYPES = [NEVER, DAILY, WEEKLY, MONTHLY].freeze

  self.include_root_in_json = false

  belongs_to :organization
  belongs_to :sync_task, class_name: 'ForemanTasks::Task'
  has_many :scc_products, dependent: :destroy
  has_many :scc_repositories, dependent: :destroy
  belongs_to :foreman_tasks_recurring_logic, :inverse_of => :scc_account, :class_name => 'ForemanTasks::RecurringLogic', :dependent => :destroy
  belongs_to :task_group, :class_name => 'SccAccountSyncPlanTaskGroup', :inverse_of => :scc_account

  validates_lengths_from_database
  validates :name, presence: true
  validates :organization, presence: true
  validates :login, presence: true
  validates :password, presence: true
  validates :base_url, presence: true
  validates :interval, :inclusion => { :in => TYPES }, :allow_blank => false
  validate :sync_date_is_valid_datetime

  after_initialize :init
  before_destroy :cancel_recurring_logic

  default_scope -> { order(:login) }

  scoped_search on: :login, complete_value: true
  scoped_search on: :name

  def init
    # set default values
    self.sync_date ||= Time.new if self.new_record?
  end

  def sync_date_is_valid_datetime
    errors.add(:sync_date, 'must be a valid datetime') if interval != NEVER &&
                                                          sync_date.present? &&
                                                          !sync_date.respond_to?(:min) &&
                                                          !sync_date.respond_to?(:hour) &&
                                                          !sync_date.respond_to?(:wday) &&
                                                          !sync_date.respond_to?(:day)
  end

  def to_s
    name
  end

  def sync_status
    if sync_task.nil?
      _('never synced')
    elsif sync_task.state == 'stopped'
      if sync_task.result == 'success'
        synced
      else
        sync_task.result
      end
    else
      sync_task.state
    end
  end

  def use_recurring_logic?
    self.interval != NEVER
  end

  def save_with_logic!
    self.task_group ||= SccAccountSyncPlanTaskGroup.create!

    associate_recurring_logic if self.valid?

    self.save!
    start_recurring_logic if self.use_recurring_logic?

    true
  end

  def update_attributes_with_logic!(params)
    transaction do
      self.update!(params)
      if rec_logic_changed?
        old_rec_logic = self.foreman_tasks_recurring_logic
        associate_recurring_logic
        self.save!
        old_rec_logic&.cancel
        # Can/Should we do that???
        old_rec_logic&.destroy
        start_recurring_logic
      end
      toggle_enabled if enabled_toggle?
    end
    true
  end

  def add_recurring_logic(sync_date, interval)
    sd = sync_date

    raise _('Interval cannot be nil') if interval.nil?

    cron = case interval.downcase
           when DAILY   then "#{sd.min} #{sd.hour} * * *"
           when WEEKLY  then "#{sd.min} #{sd.hour} * * #{sd.wday}"
           when MONTHLY then "#{sd.min} #{sd.hour} #{sd.day} * *"
           else
             raise _('Interval not set correctly')
           end

    recurring_logic = ForemanTasks::RecurringLogic.new_from_cronline(cron)

    raise _('Cron expression is not valid!') unless recurring_logic.valid_cronline?

    recurring_logic.save!
    recurring_logic
  end

  def associate_recurring_logic
    if self.use_recurring_logic?
      self.foreman_tasks_recurring_logic = add_recurring_logic(self.sync_date, self.interval)
    else
      self.foreman_tasks_recurring_logic = nil
    end
  end

  def toggle_enabled
    self.foreman_tasks_recurring_logic&.enabled = self.enabled
  end

  def start_recurring_logic
    # rubocop:disable Style/GuardClause
    if self.use_recurring_logic?
      User.as_anonymous_admin do
        if self.sync_date.to_time < Time.now
          self.foreman_tasks_recurring_logic.start(::Actions::SccManager::SyncPlanAccountRepositories, self)
        else
          self.foreman_tasks_recurring_logic.start_after(::Actions::SccManager::SyncPlanAccountRepositories, self.sync_date, self)
        end
      end
    end
    # rubocop:enable Style/GuardClause
  end

  def cancel_recurring_logic
    self.foreman_tasks_recurring_logic&.cancel
  end

  def rec_logic_changed?
    saved_change_to_attribute?(:sync_date) || saved_change_to_attribute?(:interval)
  end

  def enabled_toggle?
    saved_change_to_attribute?(:enabled)
  end

  def get_scc_data(rel_url)
    SccManager.get_scc_data(base_url, rel_url, login, password)
  end

  def test_connection
    get_scc_data('/connect/organizations/subscriptions')
    true
  rescue StandardError => e
    ::Foreman::Logging.logger('foreman_scc_manager').warn "Error occurred while testing SCC-Connection to Account #{self}: #{e}"
    false
  end

  def update_scc_repositories(upstream_repositories)
    upstream_repo_ids = []
    # initially invalidate all repositories and validate them during update
    invalidated_repos = invalidate_subscription_status(scc_repositories)
    # import repositories
    upstream_repositories.each do |ur|
      cached_repository = scc_repositories.find_or_initialize_by(scc_id: ur['id'])
      cached_repository.distro_target = ur['distro_target']
      cached_repository.description = ur['description']
      cached_repository.url, cached_repository.token = ur['url'].split('?')
      cached_repository.enabled = ur['enabled']
      cached_repository.autorefresh = ur['autorefresh']
      cached_repository.installer_updates = ur['installer_updates']
      # should be called after all attributes are set in case of dependencies (currently: description)
      cached_repository.name = cached_repository.pretty_name
      cached_repository.subscription_valid = true
      cached_repository.save!
      upstream_repo_ids << ur['id']
      # set invalidated record to true, if exists
      invalidated_repos = revalidate_subscription_status(invalidated_repos, ur[id])
    end
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Found #{upstream_repo_ids.length} repositories"

    # all scc repos that are kept but not available upstream need to be marked invalid
    # subscription_valid can be set to nil
    to_invalidate = invalidated_repos.select { |ir| ir.katello_root_repository_id.present? && !ir.subscription_valid }
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Invalidating #{to_invalidate.count} expired repositories"
    invalidate_subscription_status(to_invalidate, true)

    # delete repositories being removed upstream and that are not subscribed to
    to_delete = scc_repositories.where.not(scc_id: upstream_repo_ids)
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Deleting #{to_delete.count} old repositories"
    to_delete.destroy_all
  end

  def update_scc_products(upstream_products)
    upstream_product_ids = []
    # initially invalidate all products and validate them during update
    invalidated_products = invalidate_subscription_status(scc_products)
    # import products
    upstream_products.each do |up|
      cached_product = scc_products.find_or_initialize_by(scc_id: up['id'])
      cached_product.version = up['version']
      cached_product.arch = up['arch']
      cached_product.description = up['description']
      cached_product.friendly_name = up['friendly_name']
      cached_product.product_type = up['product_type']
      cached_product.scc_repositories =
        scc_repositories.where(scc_id: up['repositories'].map { |repo| repo['id'] })
      # name should be set after friendly_name because it depends on friendly_name
      cached_product.name = cached_product.pretty_name
      cached_product.description = cached_product.pretty_description
      cached_product.subscription_valid = true
      cached_product.save!
      upstream_product_ids << up['id']
      # set invalidated record to true, if exists
      invalidated_products = revalidate_subscription_status(invalidated_products, up['id'])
    end
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Found #{upstream_product_ids.length} products"

    # all scc products that are kept but not available upstream need to be marked invalid
    # subscription_valid can be set to nil
    to_invalidate = invalidated_products.select { |ip| ip.product_id.present? && !ip.subscription_valid }
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Invalidating #{to_invalidate.count} expired products"
    invalidate_subscription_status(to_invalidate, true)

    # delete products being removed upstream and that are not subscribed to
    to_delete = scc_products.where.not(scc_id: upstream_product_ids).where(product_id: nil)
    ::Foreman::Logging.logger('foreman_scc_manager').debug "Deleting #{to_delete.count} old products"
    to_delete.destroy_all
    # rewire product to product relationships
    upstream_products.each do |up|
      extensions = scc_products.where(scc_id: up['extensions'].map { |ext| ext['id'] })
      begin
        scc_products.find_by!(scc_id: up['id']).update!(scc_extensions: extensions)
      rescue ActiveRecord::RecordNotFound
        ::Foreman::Logging.logger('foreman_scc_manager').info "Failed to find parent scc_product '#{up['name']}'."
      end
    end
  end

  # validate the subscription status of a product/repo
  # no saving to database
  # params: elements: scc repos or products, Array or ActiveRecord_(*)
  #         scc_id: scc_id of the element that should be revalidated
  # return: elements where for the element with scc_id subscription_valid is true
  def revalidate_subscription_status(elements, scc_id)
    return nil if elements.nil?

    revalidate = elements.find { |e| e.scc_id == scc_id }
    revalidate.subscription_valid = true unless revalidate.nil?
    # return modified list
    elements
  end

  # set all products/repos invalid
  # params: items_to_invalidate: ActiveRecord_(*)
  #         save_record: store in database or not (default)
  # return: ActiveRecord elements with invalidated subscription status
  def invalidate_subscription_status(items_to_invalidate, save_record = false)
    if items_to_invalidate.present?
      items_to_invalidate.each do |inv|
        inv.subscription_valid = false
        inv.save! if save_record
      end
    end
    items_to_invalidate
  end
end
