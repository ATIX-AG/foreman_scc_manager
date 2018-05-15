class RemoveRepositoriesFromSccProducts < ActiveRecord::Migration[4.2]
  def change
    remove_column :scc_products, :repositories, :string
  end
end
