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

    test 'set? scc_registered finds registered hosts' do
      unregistered = FactoryBot.create(:host)
      results = Host::Managed.search_for('set? scc_registered')
      assert_includes results, @host
      assert_not_includes results, unregistered
    end

    test 'null? scc_registered finds unregistered hosts' do
      unregistered = FactoryBot.create(:host)
      results = Host::Managed.search_for('null? scc_registered')
      assert_includes results, unregistered
      assert_not_includes results, @host
    end

    test 'destroying a host destroys its facet, credentials, and products' do
      facet_id = @host.scc_facet.id
      credentials_id = @host.scc_host_credentials.id
      scc_host_product = @host.scc_host_products.create!(scc_product: scc_products(:one), status: SccHostProduct::ACTIVE)

      assert @host.destroy

      assert_empty SccFacet.where(id: facet_id)
      assert_empty SccHostCredentials.where(id: credentials_id)
      assert_empty SccHostProduct.where(id: scc_host_product.id)
    end
  end
end
