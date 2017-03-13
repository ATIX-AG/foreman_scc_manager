class SccRepository < ActiveRecord::Base
  after_save :token_changed_callback, if: :token_changed?

  self.include_root_in_json = false

  belongs_to :scc_account
  has_one :organization, through: :scc_account
  has_and_belongs_to_many :scc_products

  def full_url
    token.blank? ? url : url + '?' + token
  end

  def token_changed_callback
    scc_products.where.not(product: nil).each do |sp|
      repository = sp.product.repositories.find_by(name: sp.friendly_name + ' ' + description)
      ForemanTasks::sync_task(::Actions::Katello::Repository::Update, repository, {url: full_url})
    end
  end

end
