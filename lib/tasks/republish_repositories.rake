namespace :foreman_scc_manager do
  desc 'Republish all SCC-repositories.'
  task :republish_scc_repositories => ['dynflow:client', 'katello:check_ping'] do
    needing_publish = SccKatelloRepository.joins(:katello_root_repository)
                                          .joins(:katello_root_repository => :repositories)
                                          .pluck("#{Katello::Repository.table_name}.id")
    if needing_publish.any?
      ForemanTasks.async_task(::Actions::Katello::Repository::BulkMetadataGenerate, Katello::Repository.where(:id => needing_publish))
    else
      puts 'Skipped. No repository found which was created by the SCC plugin.'
    end
  end
end
