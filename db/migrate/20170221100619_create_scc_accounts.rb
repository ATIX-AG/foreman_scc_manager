class CreateSccAccounts < ActiveRecord::Migration
  def change
    create_table :scc_accounts do |t|
      t.string :login, limit: 255
      t.string :password, limit: 255
      t.string :base_url, limit: 255, default: 'https://scc.suse.com'

      t.timestamps null: false
    end
  end
end
