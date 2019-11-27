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
        requires_foreman '>= 1.22'
        requires_foreman_plugin 'katello', '>= 3.12.0'

        apipie_documented_controllers ["#{ForemanSccManager::Engine.root}/app/controllers/api/v2/*.rb"]

        # Add permissions
        security_block :foreman_scc_manager do
          permission :view_scc, {
            :'foreman_scc_manager/scc_accounts' => [:show, :index],
            :'api/v2/scc_accounts' => [:show, :index]
          }
          permission :use_scc, {
            :'foreman_scc_manager/scc_accounts' => [:bulk_subscribe],
            :'api/v2/scc_accounts' => [:bulk_subscribe]
          }
          permission :new_scc, {
            :'foreman_scc_manager/scc_accounts' => [:new, :create],
            :'api/v2/scc_accounts' => [:create]
          }
          permission :edit_scc, {
            :'foreman_scc_manager/scc_accounts' => [:edit, :update],
            :'api/v2/scc_accounts' => [:update]
          }
          permission :delete_scc, {
            :'foreman_scc_manager/scc_accounts' => [:destroy],
            :'api/v2/scc_accounts' => [:destroy]
          }
          permission :sync_scc, {
            :'foreman_scc_manager/scc_accounts' => [:sync],
            :'api/v2/scc_accounts' => [:sync]
          }
        end

        # Add a new role called 'SccManager' if it doesn't exist
        role 'SccManager', %i[view_scc use_scc new_scc edit_scc delete_scc sync_scc]

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
