class AddSuseIdentifierToSccProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :scc_products, :suse_identifier, :string, null: true
  end
end
