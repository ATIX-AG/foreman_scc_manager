module Actions
  module SccManager
    class SubscribeProduct < Actions::EntryAction
      # scc_product is an ActiveRecord object of Class SccProduct
      # scc_repos_to_subscribe is a hash with the product id as keys and an array of
      # repos to subscribe as values
      # rubocop:disable Metrics/MethodLength
      def plan(scc_product, scc_repos_to_subscribe)
        if scc_product.product
          ::Foreman::Logging.logger('foreman_scc_manager')
                            .info("SccProduct '#{scc_product.friendly_name}' is already subscribed to.")
        else
          ::Foreman::Logging.logger('foreman_scc_manager')
                            .info("Initiating subscription for SccProduct '#{scc_product.friendly_name}'.")
        end

        sequence do
          if scc_product.product_id.nil?
            product_create_action = plan_action(CreateProduct,
              :product_name => scc_product.pretty_name,
              :product_description => scc_product.pretty_description,
              :organization_id => scc_product.organization.id,
              :gpg_key => scc_product.scc_account.katello_gpg_key_id)
          end
          katello_repos = {}
          # we need to set the repositories to subscribe to
          scc_repos = []
          if scc_repos_to_subscribe.empty?
            scc_repos = scc_product.scc_repositories
          else
            # at this point, we need to make sure that the repository list is valid
            # we want to subscribe only to repos that we have not subscribed before
            repo_ids_katello = scc_product.product.blank? || scc_product.product.root_repository_ids.blank? ? nil : scc_product.product.root_repository_ids
            scc_repos = scc_product.scc_repositories.where(id: scc_repos_to_subscribe[scc_product.id])
            unless repo_ids_katello.nil? || scc_repos.empty?
              # remove repo if Katello repo is already associated
              scc_repos.reject { |repo| (repo.katello_root_repositories & repo_ids_katello).present? }
            end
          end
          if scc_repos.empty?
            ::Foreman::Logging.logger('foreman_scc_manager')
                              .info('The repositories you have selected are either already subscribed to or invalid.')
          else
            ::Foreman::Logging.logger('foreman_scc_manager')
                              .info("Subscribing to SCC repositories '#{scc_repos.pluck(:id)}'.
                                    If you requested more repositories, please check if those are already subscribed to or invalid.")
          end
          scc_repos.each do |repo|
            arch = scc_product.arch || 'noarch'
            repo_create_action = plan_action(CreateRepository,
              :product_id => scc_product.product_id || product_create_action.output[:product_id],
              :uniq_name => repo.uniq_name(scc_product),
              :pretty_repo_name => repo.pretty_name,
              :url => repo.url,
              :token => repo.token,
              :arch => arch,
              :download_policy => scc_product.scc_account.download_policy,
              :mirroring_policy => scc_product.scc_account.mirroring_policy)
            katello_repos[repo.id] = repo_create_action.output[:katello_root_repository_id]
          end

          # connect action to resource (=> make parameters accessable in input)
          action_subject(scc_product, product_id: product_create_action.output[:product_id]) if scc_product.product_id.nil?
          input.update(katello_repos: katello_repos)
          plan_self
        end
      end
      # rubocop:enable Metrics/MethodLength

      def finalize
        # connect Scc products and Katello products
        # it may happen that we only append repos to an existing product
        unless input[:scc_product].nil?
          scc_product = SccProduct.find(input[:scc_product][:id])
          scc_product.update!(product_id: input[:product_id])
        end
        # extract Katello repo ids from input hash and store to database
        input[:katello_repos].each do |scc_repo_id, katello_root_repository_id|
          SccKatelloRepository.find_or_create_by(scc_repository_id: scc_repo_id, katello_root_repository_id: katello_root_repository_id)
        end
      end

      def humanized_name
        _('Subscribe SCC Product')
      end
    end

    class CreateProduct < Actions::Base
      middleware.use ::Actions::Middleware::KeepCurrentUser
      include ::Dynflow::Action::WithSubPlans

      def create_sub_plans
        product = ::Katello::Product.new
        product.name = input[:product_name]
        if ::Katello.const_defined?(:ContentCredential)
          product.gpg_key = ::Katello::ContentCredential.find_by(id: input[:gpg_key], organization: input[:organization_id])
        else
          product.gpg_key = ::Katello::GpgKey.find_by(id: input[:gpg_key], organization: input[:organization_id])
        end
        product.description = input[:product_description]
        trigger(::Actions::Katello::Product::Create,
          product,
          Organization.find(input[:organization_id])).tap do
          output[:product_id] = product.id
        end
      end
    end

    class CreateRepository < Actions::Base
      middleware.use ::Actions::Middleware::KeepCurrentUser
      include ::Dynflow::Action::WithSubPlans

      def create_sub_plans
        product = ::Katello::Product.find(input[:product_id])
        label = ::Katello::Util::Model.labelize(input[:uniq_name])
        unprotected = true
        gpg_key = product.gpg_key
        repo_param = { :label => label,
                       :name => input[:pretty_repo_name],
                       :content_type => 'yum',
                       :unprotected => unprotected,
                       :gpg_key => gpg_key,
                       :arch => input[:arch],
                       :download_policy => input[:download_policy],
                       :mirroring_policy => input[:mirroring_policy] }
        repository = product.add_repo(repo_param)
        if repository.has_attribute?('upstream_authentication_token')
          repository.url = input[:url]
          repository.upstream_authentication_token = input[:token]
        else
          repository.url = input[:token].blank? ? input[:url] : "#{input[:url]}?#{input[:token]}"
        end

        repository.verify_ssl_on_sync = true
        trigger(::Actions::Katello::Repository::CreateRoot, repository).tap do
          output[:katello_root_repository_id] = repository.id
        end
      end
    end
  end
end
