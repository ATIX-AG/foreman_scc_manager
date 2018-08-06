class SccProductsController < ApplicationController
  before_action :find_resource, only: %i[show subscribe unsubscribe]
  include Foreman::Controller::AutoCompleteSearch

  def index
    # TODO: Organization...
    @scc_products = SccProduct.all
    respond_to do |format|
      format.json { render json: @scc_products.to_json }
    end
  end

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
