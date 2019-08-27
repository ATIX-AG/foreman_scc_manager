module Api
  module V2
    class SccProductsController < V2::BaseController
      include Api::Version2
      include Foreman::Controller::AutoCompleteSearch

      before_action :find_resource, :only => [:show, :subscribe, :unsubscribe]

      api :GET, '/scc_accounts/:id', N_('List all scc_account products')
      param :id, :identifier_dottable, :required => true
      param :organisation_id, :identifier_dottable, :required => true

      def index
        # TODO: Organization...
        @scc_products = SccProduct.all
        respond_to do |format|
          format.json { render json: @scc_products.to_json }
        end
      end

      api :GET, '/scc_accounts/:id', N_('Show an scc_account products')
      param :id, :identifier_dottable, :required => true
      param :organisation_id, :identifier_dottable, :required => true

      def show
        respond_to do |format|
          format.json { render json: @scc_product.to_json }
        end
      end

      def subscribe
        @scc_product.subscribe
        redirect_to @scc_product.scc_account
      end
    end
  end
end
