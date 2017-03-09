class CreateSccProductsSccRepositoriesJoinTable < ActiveRecord::Migration
  def change
    create_join_table :scc_products, :scc_repositories do |t|
      # t.index [:scc_product_id, :scc_repository_id]
      # t.index [:scc_repository_id, :scc_product_id]
    end
  end
end
