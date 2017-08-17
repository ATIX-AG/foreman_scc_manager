class AddOrganizationToSccAccount < ActiveRecord::Migration
  class SccAccount < ApplicationRecord
    belongs_to :organization
  end

  class Organization < ApplicationRecord
  end

  def up
    Organization.table_name = 'taxonomies'
    add_column :scc_accounts, :organization_id, :integer, null: true, index: true
    SccAccount.all.each do |a|
      a.organization = Organization.first
      a.save!
    end
    change_column :scc_accounts, :organization_id, :integer, null: false, index: true
  end

  def down
    remove_column :scc_accounts, :organization_id, :integer
  end
end
