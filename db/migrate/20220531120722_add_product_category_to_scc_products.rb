class AddProductCategoryToSccProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :scc_products, :product_category, :string, null: true
  end
end
