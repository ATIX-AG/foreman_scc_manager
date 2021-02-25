class AddRootRepositoryIdToSccRepository < ActiveRecord::Migration[5.2]
  def change
    add_column :scc_repositories, :katello_root_repository_id, :integer, index: true, null: true
    add_foreign_key :scc_repositories, :katello_root_repositories, column: :katello_root_repository_id, on_delete: :nullify
  end
end
