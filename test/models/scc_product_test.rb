require 'test_plugin_helper'

class SccProductCreateTest < ActiveSupport::TestCase
  def setup
    @product = scc_products(:one)
  end

  test 'create' do
    assert @product.save
    refute_empty SccProduct.where(id: @product.id)
  end

  test 'uniq_name' do
    assert_equal @product.uniq_name, '111 number one'
  end
end

class SccProductSearchTest < ActiveSupport::TestCase
  test 'default ordered by name' do
    assert_equal SccProduct.all.pluck(:name), ['one', 'two'].sort
  end

  test 'search name' do
    one = scc_products(:one)
    products = SccProduct.search_for("name = \"#{one.name}\"")
    assert_includes products, one
    refute_includes products, scc_products(:two)

    empty = SccProduct.search_for('name = "nothing"')
    assert_empty empty
  end
end
