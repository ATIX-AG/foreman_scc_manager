require 'test_plugin_helper'

class SccHostProductTest < ActiveSupport::TestCase
  def setup
    @host = FactoryBot.create(:host)
    @facet = @host.create_scc_facet
    @product = scc_products(:one)
  end

  test 'create with valid status' do
    shp = SccHostProduct.create(scc_facet: @facet, scc_product: @product, status: SccHostProduct::PENDING)
    assert shp.valid?
  end

  test 'rejects invalid status' do
    shp = SccHostProduct.new(scc_facet: @facet, scc_product: @product, status: 'nonsense')
    assert_not shp.valid?
  end

  test 'uniqueness per facet and product' do
    SccHostProduct.create!(scc_facet: @facet, scc_product: @product, status: SccHostProduct::ACTIVE)
    dup = SccHostProduct.new(scc_facet: @facet, scc_product: @product, status: SccHostProduct::ACTIVE)
    assert_not dup.valid?
  end

  test 'active scope returns only active' do
    active = SccHostProduct.create!(scc_facet: @facet, scc_product: @product, status: SccHostProduct::ACTIVE)
    other_facet = FactoryBot.create(:host).create_scc_facet
    pending = SccHostProduct.create!(scc_facet: other_facet, scc_product: @product, status: SccHostProduct::PENDING)
    assert_includes SccHostProduct.active, active
    assert_not_includes SccHostProduct.active, pending
  end

  test 'search by status' do
    active = SccHostProduct.create!(scc_facet: @facet, scc_product: @product, status: SccHostProduct::ACTIVE)
    failed = SccHostProduct.create!(scc_facet: FactoryBot.create(:host).create_scc_facet, scc_product: @product, status: SccHostProduct::FAILED)

    results = SccHostProduct.search_for('status = failed')
    assert_includes results, failed
    assert_not_includes results, active
  end

  test 'search by product name' do
    shp = SccHostProduct.create!(scc_facet: @facet, scc_product: @product, status: SccHostProduct::ACTIVE)
    assert_includes SccHostProduct.search_for("product_name = \"#{@product.name}\""), shp
    assert_empty SccHostProduct.search_for('product_name = "nothing"')
  end
end
