class AddSyncOptionsToSccAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :scc_accounts, :download_policy, :string, default: ::Katello::RootRepository::DOWNLOAD_IMMEDIATE
    add_column :scc_accounts, :mirroring_policy, :string, default: ::Katello::RootRepository::MIRRORING_POLICY_CONTENT
    SccAccount.all.each do |a|
      a.download_policy = ::Katello::RootRepository::DOWNLOAD_IMMEDIATE
      a.mirroring_policy = ::Katello::RootRepository::MIRRORING_POLICY_CONTENT
      a.save!
    end
  end
end
