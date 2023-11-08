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

      before_action :find_resource, :only => [:show, :update, :destroy, :sync, :bulk_subscribe, :bulk_subscribe_with_repos]

      api :GET, '/scc_accounts/', N_('List all scc_accounts')
      param :organization_id, :identifier, :required => true
      param_group :search_and_pagination, ::Api::V2::BaseController
      def index
        scope = resource_scope
        scope = scope.where(:organization => params[:organization_id]) if params[:organization_id].present?
        @scc_accounts = scope.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page], :per_page => params[:per_page])
      end

      api :GET, '/scc_accounts/:id/', N_('Show scc_account')
      param :id, :identifier_dottable, :required => true
      def show
      end

      def_param_group :scc_account do
        param :scc_account, Hash, :required => true, :action_aware => true do
          param :name, String, :required => true, :desc => N_('Name of the scc_account')
          param :login, String, :required => true, :desc => N_('Login id of scc_account')
          param :password, String, :required => true, :desc => N_('Password of scc_account')
          param :base_url, String, :required => false, :desc => N_('URL of SUSE for scc_account')
          param :interval, ['never', 'daily', 'weekly', 'monthly'], :desc => N_('Interval for syncing scc_account')
          param :download_policy,
            ::Katello::RootRepository::DOWNLOAD_POLICIES,
            :required => false,
            :desc => N_('The default download policy for repositories which were created using this SCC Account.')
          param :mirroring_policy,
            SccAccount::SCC_MIRRORING_POLICIES,
            :required => false,
            :desc => N_('The default mirroring policy for repositories which were created using this SCC Account.')
          param :sync_date, String, :desc => N_('Date and time relative to which the sync interval is run')
          param :katello_gpg_key_id, :identifier, :required => false, :desc => N_('Associated GPG key of scc_account')
        end
      end

      api :POST, '/scc_accounts/', N_('Create an scc_account')
      param_group :scc_account, :as => :create
      param :organization_id, :identifier, :required => true
      def create
        @scc_account = resource_class.new(scc_account_params)
        process_response @scc_account.save_with_logic!
      end

      api :PUT, '/scc_accounts/:id', N_('Update scc_account')
      param :id, :identifier_dottable, :required => true
      param_group :scc_account
      def update
        process_response @scc_account.update(scc_account_params)
      end

      api :DELETE, '/scc_accounts/:id', N_('Delete scc_account')
      param :id, :identifier_dottable, :required => true
      def destroy
        process_response @scc_account.destroy
      end

      api :POST, '/scc_accounts/test_connection', N_('Test connection for scc_account')
      api :PUT, '/scc_accounts/:id/test_connection', N_('Test connection for scc_account')
      param :id, :identifier_dottable, :required => false
      param :login, String, :required => false, :desc => N_('Login id of scc_account')
      param :password, String, :required => false, :desc => N_('Password of scc_account')
      param :base_url, String, :required => false, :desc => N_('URL of SUSE for scc_account')
      def test_connection
        if params[:id].present?
          find_resource
          begin
            local_scc_account_params = scc_account_params
          rescue ActionController::ParameterMissing
            local_scc_account_params = {}
          end
          @scc_account.login = local_scc_account_params[:login] unless local_scc_account_params[:login].empty?
          @scc_account.password = local_scc_account_params[:password] unless local_scc_account_params[:password].empty?
        else
          @scc_account = resource_class.new(scc_account_params)
        end
        respond_to do |format|
          if @scc_account.test_connection
            format.json { render json: { 'success' => true }.to_json, status: :ok }
          else
            format.json { render json: { 'success' => false, 'error' => 'Test failed. Check your credentials.' }.to_json, status: :not_found }
          end
        end
      end

      api :PUT, '/scc_accounts/:id/sync', N_('Sync scc_account')
      param :id, :identifier_dottable, :required => true
      def sync
        sync_task = ForemanTasks.async_task(::Actions::SccManager::Sync, @scc_account)
        synced = @scc_account.update! sync_task: sync_task
        respond_to do |format|
          format.json { render json: sync_task.to_json } if synced
        end
      rescue ::Foreman::Exception => e
        render json: { error: ('Failed to add task to queue: %s' % e).to_s }, status: :unprocessable_entity
      rescue ForemanTasks::Lock::LockConflict => e
        render json: { error: ('Lock on SCC account already taken: %s' % e).to_s }, status: :unprocessable_entity
      end

      api :PUT, '/scc_accounts/:id/bulk_subscribe/', N_('Bulk subscription of scc_products for scc_account')
      param :id, :identifier_dottable, :required => true
      param :scc_subscribe_product_ids, Array, :required => true
      def bulk_subscribe
        respond_to do |format|
          if params[:scc_subscribe_product_ids].count > 0
            # we need to pass two parameters to the product subscribe task,
            # the product itself and an array of repo ids
            # if the id array is empty, all repositories will be subscribed to
            scc_products = @scc_account.scc_products.where(:id => params[:scc_subscribe_product_ids])
            subscribe_task = ForemanTasks.async_task(::Actions::BulkAction,
              ::Actions::SccManager::SubscribeProduct,
              scc_products,
              {})
            format.json { render json: subscribe_task.to_json, status: :ok }
          else
            format.json { render json: { error: 'No Product selected' }, status: :expectation_failed }
          end
        end
      rescue ::Foreman::Exception => e
        render json: { error: ('Failed to add task to queue: %s' % e).to_s }, status: :unprocessable_entity
      rescue ForemanTasks::Lock::LockConflict => e
        render json: { error: ('Lock on SCC account already taken: %s' % e).to_s }, status: :unprocessable_entity
      end

      def_param_group :scc_product_data do
        param :scc_product_data, Array, :required => true, :desc => 'Array of Hash elements. One hash element contains an scc_product_id and a repository_list.' do
          param :scc_product_id, Integer, :required => true, :desc => 'Product ID of SCC product'
          param :repository_list, Array, of: Integer, required: false,
                                         desc: 'List of SCC repositories belonging to the SCC product. If the list is empty, all repositories will be subscribed to.'
        end
      end

      api :PUT, '/scc_accounts/:id/bulk_subscribe_with_repos/', N_('Bulk subscription of scc_products with individual repository selection for scc_account.')
      param :id, :identifier_dottable, :required => true
      param_group :scc_product_data
      def bulk_subscribe_with_repos
        respond_to do |format|
          # if we want to subscribe to specific repos, we need to pass the product and the
          # corresponding repository ids instead of scc products only
          if params[:scc_product_data].count > 0
            scc_products = @scc_account.scc_products.where(:id => params[:scc_product_data].pluck(:scc_product_id))
            if scc_products.empty?
              format.json { render json: { error: _('The selected products cannot be found for this SCC account.') }, status: :unprocessable_entity }
            else
              action_args = params[:scc_product_data].map { |p| { p['scc_product_id'] => p['repository_list'] } }.inject(:merge)
              subscribe_task = ForemanTasks.async_task(::Actions::BulkAction,
                ::Actions::SccManager::SubscribeProduct,
                scc_products,
                action_args)
              format.json { render json: subscribe_task.to_json, status: :ok }
            end
          else
            format.json { render json: { error: 'No Product selected' }, status: :expectation_failed }
          end
        end
      rescue ::Foreman::Exception => e
        render json: { error: ('Failed to add task to queue: %s' % e).to_s }, status: :unprocessable_entity
      rescue ForemanTasks::Lock::LockConflict => e
        render json: { error: ('Lock on SCC account already taken: %s' % e).to_s }, status: :unprocessable_entity
      end

      private

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

      def find_resource
        @scc_account = resource_class.find(params[:id])
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
        when 'bulk_subscribe_with_repos'
          :bulk_subscribe_with_repos
        else
          super
        end
      end
    end
  end
end
