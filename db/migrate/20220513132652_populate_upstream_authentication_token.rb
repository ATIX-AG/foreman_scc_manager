class PopulateUpstreamAuthenticationToken < ActiveRecord::Migration[6.0]
  def up
    return unless ActiveRecord::Base.connection.column_exists?('katello_root_repositories', 'upstream_authentication_token')

    scc_repositories = SccRepository.includes(:scc_katello_repositories).where.not(scc_katello_repositories: { id: nil })
    scc_repositories.each do |scc_repo|
      scc_repo.katello_root_repositories.each do |katello_repo|
        katello_repo.update!(url: scc_repo.url, upstream_authentication_token: scc_repo.token)
      end
    end
  end

  def down
    return if ActiveRecord::Base.connection.column_exists?('katello_root_repositories', 'upstream_authentication_token')

    scc_repositories = SccRepository.includes(:scc_katello_repositories).where.not(scc_katello_repositories: { id: nil })
    scc_repositories.each do |scc_repo|
      scc_repo.katello_root_repositories.each do |katello_repo|
        katello_repo.update!(url: scc_repo.full_url)
      end
    end
  end
end
