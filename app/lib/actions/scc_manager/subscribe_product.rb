module Actions
  module SccManager
    class SubscribeProduct < Actions::EntryAction
      def plan(scc_product)
        raise "Product already subscribed!" if scc_product.product
        ::Foreman::Logging.logger('foreman_scc_manager').info "Initiating subscription for SccProduct '#{scc_product.friendly_name}'."
        sequence do
          product = ::Katello::Product.new
          product.name = scc_product.friendly_name
          product.description = scc_product.description
          product_create_action = plan_action(::Actions::Katello::Product::Create, product, scc_product.organization)

          # prepare repositories, but wait for product's candlepin id (available in finalize)
          repo_ids = scc_product.scc_repositories.all.map do |repo|
            uniq_name = scc_product.friendly_name + ' ' + repo.description
            label = ::Katello::Util::Model.labelize(uniq_name)
            unprotected = true
            gpg_key = product.gpg_key
            repository = product.add_repo(label, uniq_name, repo.full_url, 'yum', unprotected, gpg_key)
            repository.arch = scc_product.arch || 'noarch'
            repository.mirror_on_sync = true
            repository.verify_ssl_on_sync = true
            repository.save!
            repository.id
          end

          action_subject(scc_product, product: product_create_action.output[:product], repo_ids: repo_ids)
          plan_self
        end
      end

      def finalize
        ::User.current = ::User.anonymous_api_admin
        scc_product = SccProduct.find(input[:scc_product][:id])
        product = ::Katello::Product.find(input[:product][:id])
        scc_product.update!(product: product)

        # create repositories for real
        # would be a lot nicer, if one could plan these tasks in plan, but product's candlepin id is only available after 'run' phase
        input[:repo_ids].each do |repo_id|
          repository = ::Katello::Repository.find(repo_id)
          ForemanTasks::async_task(::Actions::Katello::Repository::Create, repository, false, false)
        end
      ensure
        ::User.current = nil
      end

      def humanized_name
        _("Subscribe SCC Product")
      end
    end
  end
end
