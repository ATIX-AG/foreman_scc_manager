require 'katello'

module ForemanSccManager
  class Engine < ::Rails::Engine
    engine_name 'foreman_scc_manager'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    config.to_prepare do
      ForemanTasks::RecurringLogic.include Concerns::RecurringLogicExtensions
    end

    # Add any db migrations
    initializer 'foreman_scc_manager.load_app_instance_data' do |app|
      ForemanSccManager::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_scc_manager.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_scc_manager do
        requires_foreman '>= 2.1'
        requires_foreman_plugin 'katello', '>= 3.16.0'

        precompile_assets 'foreman_scc_manager/scc_accounts.js'

        apipie_documented_controllers ["#{ForemanSccManager::Engine.root}/app/controllers/api/v2/*.rb"]

        # Add permissions
        security_block :foreman_scc_manager do
          permission :view_scc_accounts,
                     { :scc_accounts => [:show, :index, :auto_complete_search],
                       :'api/v2/scc_accounts' => [:show, :index, :auto_complete_search] },
                     :resource_type => 'SccAccount'

          permission :use_scc_accounts,
                     { :scc_accounts => [:bulk_subscribe],
                       :'api/v2/scc_accounts' => [:bulk_subscribe, :bulk_subscribe_with_repos] },
                     :resource_type => 'SccAccount'

          permission :new_scc_accounts,
                     { :scc_accounts => [:new, :create],
                       :'api/v2/scc_accounts' => [:create] },
                     :resource_type => 'SccAccount'

          permission :edit_scc_accounts,
                     { :scc_accounts => [:edit, :update],
                       :'api/v2/scc_accounts' => [:update] },
                     :resource_type => 'SccAccount'

          permission :delete_scc_accounts,
                     { :scc_accounts => [:destroy],
                       :'api/v2/scc_accounts' => [:destroy] },
                     :resource_type => 'SccAccount'

          permission :sync_scc_accounts,
                     { :scc_accounts => [:sync],
                       :'api/v2/scc_accounts' => [:sync] },
                     :resource_type => 'SccAccount'

          permission :test_connection_scc_accounts,
                     { :scc_accounts => [:test_connection],
                       :'api/v2/scc_accounts' => [:test_connection] },
                     :resource_type => 'SccAccount'

          permission :view_scc_products,
                     { :scc_products => [:index, :show],
                       :'api/v2/scc_products' => [:index, :show] },
                     :resource_type => 'SccProduct'

          permission :subscribe_scc_products,
                     { :scc_products => [:subscribe, :unsubscribe],
                       :'api/v2/scc_products' => [:subscribe, :unsibscribe] },
                     :resource_type => 'SccProduct'
        end

        # Add a new role called 'SccManager' if it doesn't exist
        role 'SccManager',
             %i[view_scc_accounts use_scc_accounts new_scc_accounts edit_scc_accounts
                delete_scc_accounts sync_scc_accounts test_connection_scc_accounts
                view_scc_products subscribe_scc_products],
             'Role granting permissons to manage SUSE Subscriptions'

        role 'SccViewer',
             %i[view_scc_accounts use_scc_accounts sync_scc_accounts
                create_products view_products subscribe_scc_products view_scc_products],
             'Role granting permissons to view and use SUSE Subscriptions'

        add_all_permissions_to_default_roles

        # add menu entry
        menu :top_menu, :scc_manager,
             url_hash: { controller: :scc_accounts, action: :index },
             caption: _('SUSE Subscriptions'),
             parent: :content_menu,
             after: :red_hat_subscriptions
      end
    end

    initializer 'foreman_scc_manager.register_actions', :before => :finisher_hook do |_app|
      ForemanTasks.dynflow.require!
      action_paths = %W[#{ForemanSccManager::Engine.root}/app/lib/actions]
      ForemanTasks.dynflow.config.eager_load_paths.concat(action_paths)
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last.gsub(/\.coffee\Z/, '')
        end
      end

    initializer 'foreman_scc_manager.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

    initializer 'foreman_scc_manager.configure_assets', group: :assets do
      SETTINGS[:foreman_scc_manager] = { assets: { precompile: assets_to_precompile } }
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanSccManager::Engine.load_seed
      end
    end

    initializer 'foreman_scc_manager.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_scc_manager'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end
