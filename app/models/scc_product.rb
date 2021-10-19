# frozen_string_literal: true

class SccProduct < ApplicationRecord
  include Authorizable
  include ForemanTasks::Concerns::ActionSubject

  scope :only_products_with_repos, -> { joins(:scc_repositories).distinct }

  self.include_root_in_json = false

  belongs_to :scc_account
  belongs_to :product, class_name: 'Katello::Product'
  has_one :organization, through: :scc_account
  has_and_belongs_to_many :scc_repositories
  has_many :scc_extendings, inverse_of: :scc_product, dependent: :destroy
  has_many :scc_extensions, through: :scc_extendings
  has_many :inverse_scc_extendings,
    inverse_of: :scc_extension,
    dependent: :destroy,
    class_name: :SccExtending,
    foreign_key: :scc_extension_id
  has_many :inverse_scc_extensions, through: :inverse_scc_extendings, source: :scc_product

  default_scope -> { order(:name) }
  scoped_search on: :name, complete_value: true
  scoped_search on: :friendly_name

  def uniq_name
    "#{scc_id} " + friendly_name
  end

  def pretty_name
    friendly_name + " (id: #{scc_id})"
  end

  # Remove HTML tags (currently assumed that there are only paragraph tags)
  # Remove second HTML paragraph if available
  def pretty_description
    new_description = Nokogiri::XML(description).xpath('//p')
    # No tags to remove
    if new_description.count.zero?
      description
    else
      new_description.first.children.first.text.strip
    end
  end

  def subscribe
    raise 'Product already subscribed!' if product

    new_product = Katello::Product.new
    new_product.name = pretty_name
    new_product.description = pretty_description
    ForemanTasks.sync_task(::Actions::Katello::Product::Create, new_product, scc_account.organization)
    new_product.reload
    scc_repositories.each do |repo|
      uniq_repo_name = repo.uniq_name(self)
      label = Katello::Util::Model.labelize(uniq_repo_name)
      unprotected = true
      gpg_key = new_product.gpg_key
      new_repo = new_product.add_repo(label, uniq_repo_name, repo.full_url, 'yum', unprotected, gpg_key)
      new_repo.arch = arch || 'noarch'
      new_repo.mirror_on_sync = true
      new_repo.verify_ssl_on_sync = true
      ForemanTasks.sync_task(::Actions::Katello::Repository::Create, new_repo, false, false)
    end
    update!(product: new_product)
  end
end
