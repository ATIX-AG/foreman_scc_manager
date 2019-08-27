module Api
  module V2
    class SccAccountsController < ::Api::V2::BaseController
      include Api::Version2
      include Foreman::Controller::AutoCompleteSearch

      resource_description do
        resource_id 'scc_accounts'
        api_version 'v2'
        api_base_url '/api/v2'
      end

      before_action :find_organization
      before_action :find_resource, :only => [:show, :edit, :update, :destroy, :sync, :bulk_subscribe]

      api :GET, '/scc_accounts/', N_('List all scc_accounts')
      param_group :search_and_pagination, ::Api::V2::BaseController

      def index
        scope = resource_scope
        scope = scope.where(:organization => params[:organization_id]) if params[:organization_id].present?
        @scc_accounts = scope.search_for(params[:search], :order => params[:order])
                      .paginate(:page => params[:page])
      end

      api :GET, '/scc_accounts/:id/', N_('Show an scc_account')
      param :id, :identifier_dottable, :required => true

      def show; end

      def_param_group :scc_account do
        param :scc_account, Hash, :required => true, :action_aware => true do
          param :name, String, :required => true, :desc => N_('Name of this scc_account')
          param :login, String, :required => true, :desc => N_('Login id of this scc_account')
          param :password, String, :required => true, :desc => N_('Password of this scc_account')
          param :base_url, String, :required => true, :desc => N_('URL of SUSE')
          param :interval, ['never', 'daily', 'weekly', 'monthy'], :desc => N_('Interval for syncing of this scc_account')
          param :sync_date, String, :desc => N_('Last Sync Date of this scc_account')
        end
      end

      api :GET, '/scc_accounts/new/', N_('New scc_account form')

      def new
        @scc_account = resource_class.new
        @scc_account.organization = @organization
      end

      api :POST, '/scc_accounts/', N_('Create an scc_account')
      param_group :scc_account, :as => :create

      def create
        process_response @scc_account.create
        @scc_account = resource_class.new(scc_account_params)
      end

      api :PUT, '/scc_accounts/:id', N_('Update an scc_account')
      param :id, :identifier_dottable, :required => true
      param_group :scc_account

      def update
        process_response @scc_account.update_attributes(scc_account_params)
      end

      api :DELETE, '/scc_account/:id', N_('Delete an scc_account')
      param :id, :identifier_dottable, :required => true

      def destroy
        process_response @scc_account.destroy
      end

      api :GET, '/scc_account/:id/edit', N_('Edit an scc_account')
      param :id, :identifier_dottable, :required => true

      def edit
      end


      api :GET, '/scc_accounts/test_connection', N_('Test connection for an scc_account')
      param :id, :identifier_dottable, :required => true

      def test_connection
        @scc_account = resource_class.new(scc_account_params)
        @scc_account.password = SccAccount.find_by!(id: params[:scc_account_id]).password if params[:scc_account_id].present? && scc_account_params[:password].empty?
        respond_to do |format|
          if @scc_account.test_connection
            format.json { render json: nil, status: :OK }
          else
            format.json { render json: nil, status: :Not_found }
          end
        end
      end

      api :PUT, '/scc_account/:id/sync', N_('Sync an scc_account')
      param :id, :identifier_dottable, :required => true

      def sync
        sync_task = ForemanTasks.async_task(::Actions::SccManager::Sync, @scc_account)
        @scc_account.update! sync_task: sync_task
        success _('Sync task has started.')
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
          success _('Task to subscribe scc products started.')
        else
          warning _('No scc products selected.')
        end
      rescue ::Foreman::Exception => e
        error _('Failed to add task to queue: %s') % e.to_s
      rescue ForemanTasks::Lock::LockConflict => e
        error _('Lock on SCC account already taken: %s') % e.to_s
      ensure
        redirect_to scc_accounts_path
      end

      def scc_bulk_subscribe_params
        params.require(:scc_account).permit(:scc_subscribe_product_ids => [])
      end

      def find_resource
        @scc_account = resource_class.find(params[:id])
      end

      def find_organization
        @organization = Organization.current
        redirect_to '/select_organization?toState=' + request.path unless @organization
      end

      def resource_class
        ::SccAccount
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
  end
end
