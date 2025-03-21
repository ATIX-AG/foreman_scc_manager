require 'test_plugin_helper'

class HostManagedExtensionsTest < ActiveSupport::TestCase
  context 'default host behavior' do
    def setup
      @host = FactoryBot.create(:host)
    end

    test 'create' do
      assert @host.save
      assert_not_empty Host::Managed.where(id: @host.id)
    end

    test 'destroy' do
      host_id = @host.id
      assert @host.destroy
      assert_empty Host::Managed.where(id: host_id)
    end
  end

  context 'SccHostCredentials extension' do
    def setup
      @host = FactoryBot.create(:host, :with_scc_host_credentials)
    end

    test 'create' do
      assert @host.save
      assert @host.scc_host_credentials
      assert_not_empty Host::Managed.where(id: @host.id)
    end

    test 'destroy' do
      host_id = @host.id
      assert @host.destroy
      assert_empty Host::Managed.where(id: host_id)
    end

    test 'scc_host_credentials relation' do
      assert @host.scc_host_credentials
      assert @host.scc_host_credentials.id
      credentials = SccHostCredentials.where(id: @host.scc_host_credentials.id).first
      assert credentials
      assert_equal credentials.scc_login, @host.scc_host_credentials.scc_login
      assert_equal credentials.scc_password, @host.scc_host_credentials.scc_password
    end
  end
end
