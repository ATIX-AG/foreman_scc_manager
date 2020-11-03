class SccRepository < ApplicationRecord
  after_commit :token_changed_callback

  self.include_root_in_json = false

  belongs_to :scc_account
  has_one :organization, through: :scc_account
  has_and_belongs_to_many :scc_products

  def full_url
    token.blank? ? url : url + '?' + token
  end

  def uniq_name(scc_product)
    scc_product.uniq_name + ' ' + description
  end

  def pretty_name
    description
  end

  def token_changed_callback
    User.current ||= User.anonymous_admin
    scc_products.where.not(product: nil).find_each do |sp|
      reponame = uniq_name(sp)
      repository = sp.product.root_repositories.find_by(name: reponame)
      unless repository.nil? || repository.url == full_url
        ::Foreman::Logging.logger('foreman_scc_manager').info "Update URL-token for repository '#{reponame}'."
        ForemanTasks.async_task(::Actions::Katello::Repository::Update, repository, url: full_url)
      end
    end
  end
end
