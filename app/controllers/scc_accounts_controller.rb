class SccAccountsController < ApplicationController
  helper_method :scc_filtered_products
  helper_method :create_nested_product_tree
  before_action :find_organization
  before_action :find_resource, only: %i[show edit update destroy sync bulk_subscribe]
  before_action :find_available_gpg_keys, only: %i[new edit update create]
  include Foreman::Controller::AutoCompleteSearch

  # GET /scc_accounts
  def index
    @scc_accounts = resource_base.where(organization: @organization)
                                 .search_for(params[:search], order: params[:order])
                                 .paginate(:page => params[:page], :per_page => params[:per_page])
    # overwrite the product list with filtered products that do not include products with empty repositories
    @scc_accounts.each do |scc_account|
      scc_account.scc_products_with_repos_count = scc_account.scc_products.only_products_with_repos.count
    end
  end

  # GET /scc_accounts/new
  def new
    @scc_account = SccAccount.new
    @scc_account.organization = @organization
  end

  # POST /scc_accounts
  def create
    @scc_account = SccAccount.new(scc_account_params)
    @scc_account.save_with_logic!
    process_success
  rescue ActiveRecord::RecordInvalid
    process_error
  end

  # GET /scc_accounts/1/edit
  def edit; end

  # POST /scc_accounts/test_connection
  def test_connection
    @scc_account = SccAccount.new(scc_account_params)
    @scc_account.password = SccAccount.find(params[:scc_account_id]).password if params[:scc_account_id].present? && scc_account_params[:password].empty?
    respond_to do |format|
      if @scc_account.test_connection
        format.json { render json: nil, status: :ok }
      else
        format.json { render json: nil, status: :not_found }
      end
    end
  end

  # PATCH/PUT /scc_accounts/1
  def update
    @scc_account.update_attributes_with_logic!(scc_account_params)
    process_success
  rescue ActiveRecord::RecordInvalid
    process_error
  end

  # DELETE /scc_accounts/1
  def destroy
    if @scc_account.destroy
      process_success
    else
      process_error
    end
  end

  # PUT /scc_accounts/1/sync
  def sync
    sync_task = ForemanTasks.async_task(::Actions::SccManager::Sync, @scc_account)
    @scc_account.update! sync_task: sync_task
    success _('Sync task started.')
  rescue ::Foreman::Exception => e
    error _('Failed to add task to queue: %s') % e.to_s
  rescue ForemanTasks::Lock::LockConflict => e
    error _('Lock on SCC account already taken: %s') % e.to_s
  ensure
    redirect_to scc_accounts_path
  end

  def bulk_subscribe
    scc_products_to_subscribe =
      @scc_account.scc_products.where(id: scc_bulk_subscribe_params[:scc_subscribe_product_ids])

    if scc_products_to_subscribe.count > 0
      ForemanTasks.async_task(::Actions::BulkAction,
                              ::Actions::SccManager::SubscribeProduct,
                              scc_products_to_subscribe)
      success _('Task to subscribe products started.')
    else
      warning _('No products selected.')
    end
  rescue ::Foreman::Exception => e
    error _('Failed to add task to queue: %s') % e.to_s
  rescue ForemanTasks::Lock::LockConflict => e
    error _('Lock on SCC account already taken: %s') % e.to_s
  ensure
    redirect_to scc_accounts_path
  end

  def create_nested_product_tree(scc_products, subscribed_only:)
    if subscribed_only
      scc_products_base = scc_products.where(:product_type => 'base').where.not(:product_id => nil).includes([:scc_extensions])
    else
      scc_products_base = scc_products.where(:product_type => 'base').includes([:scc_extensions])
    end
    tree = []
    scc_products_base.each do |p|
      tree.push(get_product_tree_hash(p))
    end

    tree
  end

  def scc_product_hash(scc_product)
    scc_product_json = scc_product.as_json(:only => [:scc_id, :id, :arch, :version, :product_id, :subscription_valid],
                                           include: { :scc_repositories => { :only => [:id, :name, :subscription_valid] } })
                                  .merge('name' => scc_product.pretty_name, 'product_category' => scc_product.product_category)
    # find if and which Katello root repository is associated with this SCC product
    repo_ids_katello = scc_product.product.blank? || scc_product.product.root_repository_ids.blank? ? nil : scc_product.product.root_repository_ids
    scc_product_json['scc_repositories'].each do |repo|
      # byebug
      if repo_ids_katello.blank?
        repo['katello_root_repository_id'] = nil
      else
        repo_ids_scc = scc_product.scc_repositories.find(repo['id']).katello_root_repository_ids
        repo['katello_root_repository_id'] = repo_ids_scc.blank? ? nil : (repo_ids_scc & repo_ids_katello).first
      end
    end
    scc_product_json
  end

  def get_product_tree_hash(scc_product_base)
    if scc_product_base.scc_extensions.blank?
      scc_product_hash(scc_product_base)
    else
      children = []
      scc_product_base.scc_extensions.each do |ext|
        children.push(get_product_tree_hash(ext))
      end
      scc_product_base_hash = scc_product_hash(scc_product_base)
      scc_product_base_hash['children'] = children
      scc_product_base_hash
    end
  end

  private

  def find_available_gpg_keys
    @scc_account ? org = @scc_account.organization : org = @organization
    if ::Katello.const_defined?(:ContentCredential)
      @selectable_gpg_keys = ::Katello::ContentCredential.where(organization: org).collect { |p| [p.name, p.id] }.unshift ['None', nil]
    else
      @selectable_gpg_keys = ::Katello::GpgKey.where(organization: org).collect { |p| [p.name, p.id] }.unshift ['None', nil]
    end
  end

  def find_organization
    @organization = Organization.current
    redirect_to "/select_organization?toState=#{request.path}" unless @organization
  end

  # Use callbacks to share common setup or constraints between actions.
  # Only allow a trusted parameter "white list" through.
  def scc_account_params
    params[:scc_account].delete(:password) if params[:scc_account][:password].blank?
    params.require(:scc_account).permit(
      :name,
      :login,
      :password,
      :base_url,
      :interval,
      :sync_date,
      :organization_id,
      :katello_gpg_key_id
    )
  end

  def scc_bulk_subscribe_params
    params.require(:scc_account).permit(:scc_subscribe_product_ids => [])
  end

  def action_permission
    case params[:action]
    when 'sync', 'test_connection'
      :sync
    when 'bulk_subscribe'
      :use
    else
      super
    end
  end

  # Function filters a product list and removes all products without valid repositories
  # The .order call is necessary to apply the ordering to repository that have already been loaded from the database.
  # Input parameters:
  # product_list: list of SccProduct
  # product_type: return only base products if type is set (default), else all
  def scc_filtered_products(product_list, product_type = 'base')
    if product_type == 'base'
      product_list.only_products_with_repos.where(product_type: 'base').order(:friendly_name)
    else
      product_list.only_products_with_repos.order(:friendly_name)
    end
  end
end
