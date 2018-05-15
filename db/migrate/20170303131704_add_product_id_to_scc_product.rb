class AddProductIdToSccProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :scc_products, :product_id, :integer, index: true, null: true
    add_foreign_key :scc_products, :katello_products, column: :product_id, on_delete: :nullify
  end
end
