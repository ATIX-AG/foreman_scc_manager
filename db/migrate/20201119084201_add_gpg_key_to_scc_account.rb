class AddGpgKeyToSccAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :scc_accounts, :katello_gpg_key_id, :integer, null: true
    if ActiveRecord::Base.connection.table_exists? :katello_content_credentials
      add_foreign_key :scc_accounts, :katello_content_credentials, column: :katello_gpg_key_id, on_delete: :nullify
    else
      add_foreign_key :scc_accounts, :katello_gpg_keys, column: :katello_gpg_key_id, on_delete: :nullify
    end
  end
end
