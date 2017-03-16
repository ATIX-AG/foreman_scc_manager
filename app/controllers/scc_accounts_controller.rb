class SccAccountsController < ApplicationController
  before_action :find_resource, only: [:show, :edit, :update, :destroy, :sync, :bulk_subscribe]
  include Api::TaxonomyScope
  include Foreman::Controller::AutoCompleteSearch

  # GET /scc_accounts
  def index
    @scc_accounts = resource_base.search_for(params[:search], order: params[:order]).paginate(page: params[:page])
  end

  # GET /scc_accounts/new
  def new
    @scc_account = SccAccount.new
    @scc_account.organization = Organization.current
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
  def edit
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
    ForemanTasks::async_task(::Actions::SccManager::Sync, @scc_account)
    redirect_to scc_accounts_path
  end

  def bulk_subscribe
    scc_products_to_subscribe = @scc_account.scc_products.where(id: scc_bulk_subscribe_params[:scc_subscribe_product_ids])
    ForemanTasks::async_task(::Actions::BulkAction, ::Actions::SccManager::SubscribeProduct, scc_products_to_subscribe)
    redirect_to scc_accounts_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # Only allow a trusted parameter "white list" through.
    def scc_account_params
      params[:scc_account].delete(:password) if params[:scc_account][:password].blank?
      params.require(:scc_account).permit(:login, :password, :base_url, :organization_id)
    end

    def scc_bulk_subscribe_params
      params.require(:scc_account).permit(:scc_subscribe_product_ids => [])
    end

    def action_permission
      case params[:action]
      when 'sync'
        :sync
      when 'bulk_subscribe'
        :bulk_subscribe
      else
        super
      end
    end
end
