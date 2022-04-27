class PopulateSccKatelloRepositories < ActiveRecord::Migration[6.0]
  class SccProduct < ApplicationRecord
    belongs_to :product, class_name: 'Katello::Product'
    has_and_belongs_to_many :scc_repositories
  end

  def up
    SccProduct.where.not(product_id: nil).each do |scc_p|
      scc_p.scc_repositories.each do |scc_r|
        # find all Katello repositories that were derived from that SCC repository
        katello_repos = Katello::RootRepository.where('label like ?', "%#{::Katello::Util::Model.labelize(scc_r.description)}%")
        scc_r.update!(katello_root_repositories: katello_repos)
      end
    end
  end
end
