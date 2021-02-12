class ConnectKatelloRootRepositoryToSccRepository < ActiveRecord::Migration[5.2]
  def up
    SccProduct.where.not(product_id: nil).each do |scc_p|
      # extract all katello root repository ids from subscribed products
      katello_root_repositories = scc_p.product.root_repositories.map { |r| [r.label, r.id] }.to_h
      # match scc repository and katello repository names
      # katello repository name can be
      # 1) equal to scc repo name
      # 2) equal to scc product id + scc product name + scc repo name
      scc_p.scc_repositories.each do |scc_r|
        katello_root_repositories.each do |katello_label, katello_id|
          scc_r.update!(katello_root_repository_id: katello_id) if katello_label.end_with?(::Katello::Util::Model.labelize(scc_r.name))
        end
      end
    end
  end
end
