module Actions
  module SccManager
    class SubscribeProduct < Actions::EntryAction
      def plan(scc_product)
        raise 'Product already subscribed!' if scc_product.product
        ::Foreman::Logging.logger('foreman_scc_manager')
                          .info("Initiating subscription for SccProduct '#{scc_product.friendly_name}'.")
        sequence do
          product_create_action = plan_action(CreateProduct,
                                              product_name: scc_product.friendly_name,
                                              product_description: scc_product.description,
                                              organization_id: scc_product.organization.id)
          concurrence do
            scc_product.scc_repositories.each do |repo|
              uniq_name = scc_product.friendly_name + ' ' + repo.description
              arch = scc_product.arch || 'noarch'
              plan_action(CreateRepository,
                          :product_id => product_create_action.output[:product_id],
                          :uniq_name => uniq_name,
                          :url => repo.full_url,
                          :arch => arch)
            end
          end
          action_subject(scc_product, product_id: product_create_action.output[:product_id])
          plan_self
        end
      end

      def finalize
        scc_product = SccProduct.find(input[:scc_product][:id])
        product = ::Katello::Product.find(input[:product_id])
        scc_product.update!(product: product)
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
        uniq_name = input[:uniq_name]
        label = ::Katello::Util::Model.labelize(uniq_name)
        unprotected = true
        gpg_key = product.gpg_key
        repository = product.add_repo(label, uniq_name, input[:url], 'yum', unprotected, gpg_key)
        repository.arch = input[:arch]
        repository.mirror_on_sync = true
        repository.verify_ssl_on_sync = true
        trigger(::Actions::Katello::Repository::Create, repository, false, false)
      end
    end
  end
end
