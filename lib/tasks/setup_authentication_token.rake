begin
  require 'rubocop/rake_task'

  namespace :foreman_scc_manager do
    desc 'Set up authentication tokens for Katello 4.3.'
    task :setup_authentication_tokens => ['environment'] do
      unless ActiveRecord::Base.connection.column_exists?('katello_root_repositories', 'upstream_authentication_token')
        puts 'Your Katello version needs to be at 4.3 and up to run this task.'
        return
      end
      begin
        scc_repositories = SccRepository.includes(:scc_katello_repositories).where.not(scc_katello_repositories: { id: nil })
        scc_repositories.each do |scc_repo|
          scc_repo.katello_root_repositories.each do |katello_repo|
            katello_repo.update!(url: scc_repo.url, upstream_authentication_token: scc_repo.token)
          end
        end
        puts 'Authentication tokens created successfully.'
      rescue StandardError => e
        puts 'There was an error while creating the authentication tokens.'
        puts e.to_s
      end
    end
  end
rescue LoadError
  # 'Rubocop not loaded.'
end
