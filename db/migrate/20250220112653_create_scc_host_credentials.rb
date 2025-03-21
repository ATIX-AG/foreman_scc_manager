class CreateSccHostCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :scc_host_credentials do |t|
      t.belongs_to :host
      t.string :scc_login, null: true
      t.string :scc_password, null: true

      t.timestamps
    end
  end
end
