require 'test_plugin_helper'

class SccFacetTest < ActiveSupport::TestCase
  def setup
    @host = FactoryBot.create(:host)
    @facet = @host.create_scc_facet
  end

  test 'belongs to a host' do
    assert_equal @host, @facet.host
  end

  test 'destroying the facet destroys its credentials and products' do
    credentials = FactoryBot.create(:scc_host_credentials, scc_facet: @facet)
    product = @facet.scc_host_products.create!(scc_product: scc_products(:one), status: SccHostProduct::ACTIVE)
    @facet.destroy
    assert_empty SccHostCredentials.where(id: credentials.id)
    assert_empty SccHostProduct.where(id: product.id)
  end

  test 'a host has at most one facet' do
    assert @host.scc_facet
    # creating a second facet for the same host should not be allowed (unique index)
    assert_raises ActiveRecord::RecordNotUnique do
      SccFacet.create!(host: @host)
    end
  end
end
