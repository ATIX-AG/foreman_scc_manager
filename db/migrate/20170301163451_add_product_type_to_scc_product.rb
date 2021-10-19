# frozen_string_literal: true

class AddProductTypeToSccProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :scc_products, :product_type, :string, limit: 63
  end
end
