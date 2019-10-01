module Api
  module V2
    class SccProductsController < ::Api::V2::BaseController
      include Api::Version2
      include Foreman::Controller::AutoCompleteSearch

      resource_description do
        resource_id 'scc_products'
        api_version 'v2'
        api_base_url '/api/v2'
      end

      before_action :find_resource, :only => [:show, :subscribe]

      api :GET, '/scc_accounts/:scc_account_id/scc_products/', N_('List all scc_account products')
      param :scc_account_id, :identifier_dottable, :required => true
      def index
        @scc_account = SccAccount.find_by!(id: params[:scc_account_id])
        @scc_products = @scc_account.scc_products
      end

      api :GET, '/scc_accounts/:scc_account_id/scc_products/:id/', N_('Show an scc_account product')
      param :id, :identifier_dottable, :required => true
      param :scc_account_id, :identifier_dottable, :required => true
      def show; end

      api :PUT, '/scc_accounts/:scc_account_id/scc_products/:id/subscribe/', N_('Subscribe product')
      param :id, :identifier_dottable, :required => true
      param :scc_account_id, :identifier_dottable, :required => true
      def subscribe
        subcribe_task = ForemanTasks.async_task(::Actions::SccManager::SubscribeProduct, @scc_product) if @scc_product
        respond_to do |format|
          if subcribe_task
            format.json { render json: subcribe_task.to_json, status: :ok }
          else
            format.json { render json: 'Failed to subscribe product'.to_json, status: :not_found }
          end
        end
      rescue ::Foreman::Exception => e
        render json: { error: ('Failed to add task to queue: %s' % e).to_s }, status: :unprocessable_entity
      rescue ForemanTasks::Lock::LockConflict => e
        render json: { error: ('Lock on SCC account already taken: %s' % e).to_s }, status: :unprocessable_entity
      end

      private

      def find_resource
        @scc_account = ::SccAccount.find_by!(id: params[:scc_account_id])
        @scc_product = @scc_account.scc_products.find_by!(id: params[:id])
      end

      def action_permission
        case params[:action]
        when 'subscribe'
          :subscribe
        else
          super
        end
      end
    end
  end
end
