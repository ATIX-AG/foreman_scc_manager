class RemoveRootRepositoryIdFromSccRepository < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :scc_repositories, :katello_root_repositories, column: :katello_root_repository_id, on_delete: :nullify
    remove_column :scc_repositories, :katello_root_repository_id, :integer, index: true, null: true
  end
end
