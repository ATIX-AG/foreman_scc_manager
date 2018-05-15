class CreateSccExtendings < ActiveRecord::Migration[4.2]
  def change
    create_table :scc_extendings do |t|
      t.references :scc_product, index: true, foreign_key: false, null: false
      t.references :scc_extension, index: true, foreign_key: false, null: false

      t.timestamps null: false
    end
    add_foreign_key :scc_extendings, :scc_products, column: :scc_product_id
    add_foreign_key :scc_extendings, :scc_products, column: :scc_extension_id
  end
end
