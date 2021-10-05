class AddGpgKeyToSccAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :scc_accounts, :katello_gpg_key_id, :integer,  null: true
    add_foreign_key :scc_accounts, :katello_content_credentials, column: :katello_gpg_key_id, on_delete: :nullify
  end
end
