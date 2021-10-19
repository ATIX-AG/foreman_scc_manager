# frozen_string_literal: true

class AddSubscriptionValidToSccProductsAndRepos < ActiveRecord::Migration[5.2]
  def change
    add_column :scc_products, :subscription_valid, :boolean, null: true
    add_column :scc_repositories, :subscription_valid, :boolean, null: true
  end
end
