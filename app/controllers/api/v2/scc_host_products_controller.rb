# frozen_string_literal: true

module Api
  module V2
    class SccHostProductsController < ::Api::V2::BaseController
      before_action :find_host

      api :GET, '/scc_hosts/:scc_host_id/products', N_('List the SUSE products activated on a host')
      param :scc_host_id, String, required: true, desc: N_('ID or name of a host')
      param :search, String, desc: N_('Filter results, e.g. "status = failed" or "product_name ~ Basesystem"')
      def index
        scc_host_products = if @host.scc_facet
                              @host.scc_host_products.includes(:scc_product).search_for(params[:search])
                            else
                              SccHostProduct.none
                            end
        render json: {
          results: scc_host_products.map { |shp| present_host_product(shp) },
        }, status: :ok
      end

      api :POST, '/scc_hosts/:scc_host_id/products', N_('Activate a SUSE product on a host')
      param :scc_host_id, String, required: true, desc: N_('ID or name of a host')
      param :scc_id, :number, required: true, desc: N_('The SUSE product ID, as shown in brackets in the SCC Manager product list')
      param :reg_code, String, required: true, desc: N_('The SUSE registration code')
      def create
        credentials = @host.scc_host_credentials
        unless credentials
          render json: { error: _('This host is not registered with the SUSE Customer Center. Register it before activating products.') }, status: :unprocessable_entity
          return
        end

        if product_params[:reg_code].blank?
          render json: { error: _('Registration code is required') }, status: :unprocessable_entity
          return
        end

        # Only look for products of the host's organization, so a host can't use
        # another organization's product if several SCC accounts are supported later.
        product = SccProduct.joins(:organization)
                            .where(taxonomies: { id: @host.organization_id })
                            .find_by(scc_id: product_params[:scc_id])
        unless product
          render json: { error: _('SUSE product not found') }, status: :not_found
          return
        end

        # refuse if already active/pending
        # allow retry if it failed
        existing = @host.scc_host_products.find_by(scc_product: product)
        if existing && existing.status != SccHostProduct::FAILED
          render json: { error: _('This product is already registered on this host.') }, status: :unprocessable_entity
          return
        end

        product_data = {
          identifier: product.suse_identifier,
          arch: product.arch,
          version: product.version,
          token: product_params[:reg_code],
        }

        scc_host_product = existing || @host.scc_facet.scc_host_products.build(scc_product: product)
        scc_host_product.update!(status: SccHostProduct::PENDING)
        task = ForemanTasks.async_task(::Actions::SccManager::ActivateProductOnScc, credentials.id, product_data, scc_host_product.id)
        scc_host_product.update!(task_id: task.id)

        render json: {
          message: _('Started product activation task.'),
          task_id: task.id,
        }, status: :accepted
      end

      api :DELETE, '/scc_hosts/:scc_host_id/products/:scc_id', N_('Deactivate a SUSE product on a host')
      param :scc_host_id, String, required: true, desc: N_('ID or name of a host')
      param :scc_id, :number, required: true, desc: N_('The SUSE product ID of the product to deactivate')
      def destroy
        credentials = @host.scc_host_credentials
        unless credentials
          render json: { error: _('This host is not registered with the SUSE Customer Center.') }, status: :unprocessable_entity
          return
        end

        scc_host_product = @host.scc_host_products.joins(:scc_product).find_by(scc_products: { scc_id: params[:id] })
        unless scc_host_product
          render json: { error: _('Activated product not found for this host.') }, status: :not_found
          return
        end

        # A failed activation never reached SCC, so there is nothing to deactivate there.
        if scc_host_product.status == SccHostProduct::FAILED
          scc_host_product.destroy!
          render json: { message: _('The product activation had failed, so it was only removed locally.') }, status: :ok
          return
        end

        if scc_host_product.status == SccHostProduct::PENDING
          render json: { error: _('The product activation is still in progress. Try again when it has finished.') }, status: :unprocessable_entity
          return
        end

        product = scc_host_product.scc_product
        product_data = {
          identifier: product.suse_identifier,
          version: product.version,
          arch: product.arch,
        }

        task = ForemanTasks.async_task(::Actions::SccManager::DeactivateProductOnScc, credentials.id, product_data, scc_host_product.id)

        render json: {
          message: _('Started product deactivation task.'),
          task_id: task.id,
        }, status: :accepted
      end

      private

      def present_host_product(scc_host_product)
        product = scc_host_product.scc_product
        {
          id: scc_host_product.id,
          scc_id: product&.scc_id,
          name: product&.name,
          identifier: product&.suse_identifier,
          version: product&.version,
          arch: product&.arch,
          task_id: scc_host_product.task_id,
          status: scc_host_product.status,
          subscription_valid: product&.subscription_valid,
        }
      end

      def find_host
        return not_found if params[:scc_host_id].blank?
        @host = resource_finder(::Host.authorized(permission_for_action), params[:scc_host_id])
      end

      def permission_for_action
        case action_name
        when 'index'
          :view_scc_hosts
        when 'create', 'destroy'
          :edit_scc_hosts
        end
      end

      def product_params
        params.permit(:scc_id, :reg_code)
      end
    end
  end
end
