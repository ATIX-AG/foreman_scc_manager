class CreateSccFacets < ActiveRecord::Migration[7.0]
  class FakeSccFacet < ApplicationRecord
    self.table_name = 'scc_facets'
  end

  class FakeSccHostCredentials < ApplicationRecord
    self.table_name = 'scc_host_credentials'
  end

  def up
    create_table :scc_facets do |t|
      t.references :host, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    create_table :scc_host_products do |t|
      t.references :scc_facet, null: false, foreign_key: true, index: false
      t.belongs_to :scc_product
      t.uuid :task_id, null: true
      t.string :status
      t.timestamps
    end
    add_index :scc_host_products, %i[scc_facet_id scc_product_id], unique: true

    add_reference :scc_host_credentials, :scc_facet, foreign_key: true, index: false

    FakeSccHostCredentials.distinct.pluck(:host_id).compact.each do |host_id|
      facet = FakeSccFacet.create!(host_id: host_id)
      FakeSccHostCredentials.where(host_id: host_id).update_all(scc_facet_id: facet.id)
    end

    change_column_null :scc_host_credentials, :scc_facet_id, false
    add_index :scc_host_credentials, :scc_facet_id, unique: true
    remove_reference :scc_host_credentials, :host
  end

  def down
    add_reference :scc_host_credentials, :host

    FakeSccFacet.find_each do |facet|
      FakeSccHostCredentials.where(scc_facet_id: facet.id).update_all(host_id: facet.host_id)
    end

    remove_index :scc_host_credentials, :scc_facet_id
    remove_reference :scc_host_credentials, :scc_facet
    drop_table :scc_host_products
    drop_table :scc_facets
  end
end
