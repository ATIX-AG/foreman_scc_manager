class FixSccPermissions < ActiveRecord::Migration[5.2]
  PERMISSION_NAMES = {
    :view_scc => :view_scc_accounts,
    :use_scc => :use_scc_accounts,
    :new_scc => :new_scc_accounts,
    :edit_scc => :edit_scc_accounts,
    :delete_scc => :delete_scc_accounts,
    :sync_scc => :sync_scc_accounts,
  }.freeze

  def up
    PERMISSION_NAMES.each do |old_n, new_n|
      Permission.find_by(name: old_n)&.update(name: new_n, resource_type: 'SccAccount')
    end
  end

  def down
    PERMISSION_NAMES.each do |old_n, new_n|
      Permission.find_by(name: new_n)&.update(name: old_n, resource_type: nil)
    end
  end
end
