class AddPermissions < ActiveRecord::Migration[6.0]
  PRODUCT_PERMISSION_NAMES = [
    'view_scc_products',
    'subscribe_scc_products'
  ].freeze

  def up
    Permission.find_or_create_by!(:name => 'test_connection_scc_accounts', :resource_type => 'SccAccount')
    PRODUCT_PERMISSION_NAMES.each do |p|
      Permission.find_or_create_by!(:name => p, :resource_type => 'SccProduct')
    end
  end

  def down
    (PRODUCT_PERMISSION_NAMES + ['test_connection_scc_accounts']).each do |p|
      Permission.where(:name => p).destroy_all
    end
  end
end
