class RemoveRepositoriesFromSccProducts < ActiveRecord::Migration
  def change
    remove_column :scc_products, :repositories, :string
  end
end
