class SccRepository < ApplicationRecord
  after_commit :token_changed_callback

  self.include_root_in_json = false

  belongs_to :scc_account
  has_many :scc_katello_repositories
  has_many :katello_root_repositories, through: :scc_katello_repositories
  has_one :organization, through: :scc_account
  has_and_belongs_to_many :scc_products

  def full_url
    token.blank? ? url : "#{url}?#{token}"
  end

  def uniq_name(scc_product)
    "#{scc_product.scc_id} #{description}"
  end

  def pretty_name
    description
  end

  def token_changed_callback
    User.current ||= User.anonymous_admin

    # get all Katello repos that were derived from this SCC repo
    # as uniq_name was changed, we need to look for repo labels that end with the repo name
    katello_repos = Katello::RootRepository.where('label like ?', "%#{::Katello::Util::Model.labelize(self.description)}%")
    katello_repos.each do |repo|
      if repo.has_attribute?('upstream_authentication_token')
        unless repo.url == url && repo.upstream_authentication_token == token
          ForemanTasks.async_task(::Actions::Katello::Repository::Update, repo, url: url, upstream_authentication_token: token)
          ::Foreman::Logging.logger('foreman_scc_manager').info "Update URL and authentication token for repository '#{repo.name}'."
        end
      else
        unless repo.url == full_url
          ForemanTasks.async_task(::Actions::Katello::Repository::Update, repo, url: full_url)
          ::Foreman::Logging.logger('foreman_scc_manager').info "Update URL-token for repository '#{repo.name}'."
        end
      end
    end
  end
end
