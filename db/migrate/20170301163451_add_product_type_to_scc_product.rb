class AddProductTypeToSccProduct < ActiveRecord::Migration
  def change
    add_column :scc_products, :product_type, :string, limit: 63
  end
end
