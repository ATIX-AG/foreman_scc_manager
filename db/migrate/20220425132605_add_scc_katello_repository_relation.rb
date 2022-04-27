class AddSccKatelloRepositoryRelation < ActiveRecord::Migration[6.0]
  def change
    create_table(:scc_katello_repositories) do |t|
      t.references :scc_repository, null: false, foreign_key: { on_delete: :cascade }
      t.references :katello_root_repository, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
