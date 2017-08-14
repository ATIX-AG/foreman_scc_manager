class SccAccountsController < ApplicationController
  before_filter :find_organization
  before_filter :find_resource, only: [:show, :edit, :update, :destroy, :sync, :bulk_subscribe]
  include Api::TaxonomyScope
  include Foreman::Controller::AutoCompleteSearch

  # GET /scc_accounts
  def index
    @scc_accounts = resource_base.search_for(params[:search], order: params[:order])
                                 .paginate(page: params[:page])
  end

  # GET /scc_accounts/new
  def new
    @scc_account = SccAccount.new
    @scc_account.organization = @organization
  end

  # POST /scc_accounts
  def create
    @scc_account = SccAccount.new(scc_account_params)
    if @scc_account.save
      process_success
    else
      process_error
    end
  end

  # GET /scc_accounts/1/edit
  def edit; end

  # POST /scc_accounts/test_connection
  def test_connection
    @scc_account = SccAccount.new(scc_account_params)
    if params[:scc_account_id].present? && scc_account_params[:password].empty?
      @scc_account.password = SccAccount.find_by!(id: params[:scc_account_id]).password
    end
    respond_to do |format|
      if @scc_account.test_connection
        format.json { render json: nil, status: :ok }
      else
        format.json { render json: nil, status: 404 }
      end
    end
  end

  # PATCH/PUT /scc_accounts/1
  def update
    if @scc_account.update(scc_account_params)
      process_success
    else
      process_error
    end
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
    begin
      sync_task = ForemanTasks.async_task(::Actions::SccManager::Sync, @scc_account)
      notice _("Sync task started.")
    rescue ::Foreman::Exception => e
      error _("Failed to add task to queue: %s") % e.to_s
    rescue ForemanTasks::Lock::LockConflict => e
      error _("Lock on SCC account already taken: %s") % e.to_s
    ensure
      redirect_to scc_accounts_path
    end
  end

  def bulk_subscribe
    begin
      scc_products_to_subscribe =
        @scc_account.scc_products.where(id: scc_bulk_subscribe_params[:scc_subscribe_product_ids])
      ForemanTasks.async_task(::Actions::BulkAction,
                              ::Actions::SccManager::SubscribeProduct,
                              scc_products_to_subscribe)
      notice _("Task to subscribe products started.")
    rescue ::Foreman::Exception => e
      error _("Failed to add task to queue: %s") % e.to_s
    rescue ForemanTasks::Lock::LockConflict => e
      error _("Lock on SCC account already taken: %s") % e.to_s
    ensure
      redirect_to scc_accounts_path
    end
  end

  private

  def find_organization
    @organization = Organization.current
    unless @organization
      redirect_to '/select_organization?toState=' + request.path
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  # Only allow a trusted parameter "white list" through.
  def scc_account_params
    params[:scc_account].delete(:password) if params[:scc_account][:password].blank?
    params.require(:scc_account).permit(:name, :login, :password, :base_url, :organization_id)
  end

  def scc_bulk_subscribe_params
    params.require(:scc_account).permit(:scc_subscribe_product_ids => [])
  end

  def action_permission
    case params[:action]
    when 'sync', 'test_connection'
      :sync
    when 'bulk_subscribe'
      :bulk_subscribe
    else
      super
    end
  end
end
