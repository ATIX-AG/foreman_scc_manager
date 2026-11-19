# frozen_string_literal: true

module Api
  module V2
    class SccHostsController < ::Api::V2::BaseController
      resource_description do
        resource_id 'scc_hosts'
        api_version 'v2'
        api_base_url '/api/v2'
      end

      before_action :find_host, only: %i[show update destroy]

      api :GET, '/scc_hosts', N_('List all hosts with their SCC registration status')
      param_group :search_and_pagination, ::Api::V2::BaseController
      param :registered, :bool, desc: N_('Only list registered (true) or unregistered (false) hosts')
      def index
        hosts = ::Host.authorized(:view_scc_hosts)
                      .includes(scc_facet: :scc_host_credentials)
                      .search_for(search_query, order: params[:order])
                      .paginate(page: params[:page], per_page: params[:per_page])
        render json: {
          results: hosts.map { |host| present_registration(host) },
        }, status: :ok
      end

      api :GET, '/scc_hosts/:id/registration', N_('Get SCC registration details for a host')
      param :id, String, required: true, desc: N_('ID or name of a host')
      def show
        credentials = @host.scc_host_credentials
        if credentials
          render json: {
            registered: true,
            registered_at: credentials.created_at,
          }, status: :ok
        else
          render json: {
            registered: false,
            message: _('This host has not been announced to the SUSE Customer Center yet.'),
          }, status: :ok
        end
      end

      api :PUT, '/scc_hosts/:id/registration', N_('Announce and register a host to SUSE Customer Center')
      param :id, String, required: true, desc: N_('ID or name of a host')
      param :reg_code, String, required: true, desc: N_('The SUSE registration code')
      def update
        if @host.scc_host_credentials
          render json: {
            message: _('This host is already announced to the SUSE Customer Center.'),
            registered: true,
          }, status: :ok
          return
        end

        if registration_params[:reg_code].blank?
          render json: { error: _('Registration code is required') }, status: :unprocessable_entity
          return
        end
        payload = ::SccManager.build_host_payload(@host)
        task = ForemanTasks.async_task(::Actions::SccManager::GetSccHostCredentials, payload, @host.id, registration_params[:reg_code])

        render json: {
          message: _('Started host announcement task.'),
          task_id: task.id,
        }, status: :accepted
      end

      api :DELETE, '/scc_hosts/:id/registration', N_('Deregister a host from the SUSE Customer Center and remove its local registration')
      param :id, String, required: true, desc: N_('ID or name of a host')
      def destroy
        credentials = @host.scc_host_credentials
        unless credentials
          render json: { message: _('No local credentials found for this host.') }, status: :not_found
          return
        end

        task = ForemanTasks.async_task(::Actions::SccManager::DeregisterHostFromScc, credentials.id)

        render json: {
          message: _('Started host deregistration task.'),
          task_id: task.id,
        }, status: :accepted
      end

      private

      def search_query
        return params[:search] unless params.key?(:registered)

        filter = Foreman::Cast.to_bool(params[:registered]) ? 'set? scc_registered' : 'null? scc_registered'
        params[:search].present? ? "(#{params[:search]}) and #{filter}" : filter
      end

      def present_registration(host)
        {
          id: host.id,
          name: host.name,
          registered: host.scc_host_credentials.present?,
          registered_at: host.scc_host_credentials&.created_at,
        }
      end

      def registration_params
        params.permit(:reg_code)
      end

      def find_host
        return not_found if params[:id].blank?
        @host = resource_finder(::Host.authorized(permission_for_action), params[:id])
      end

      def permission_for_action
        case action_name
        when 'show'
          :view_scc_hosts
        when 'update', 'destroy'
          :edit_scc_hosts
        end
      end

      def resource_class
        ::Host::Managed
      end
    end
  end
end
