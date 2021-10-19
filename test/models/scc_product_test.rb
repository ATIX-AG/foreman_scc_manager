# frozen_string_literal: true

require 'test_plugin_helper'

class SccProductCreateTest < ActiveSupport::TestCase
  def setup
    @product = scc_products(:one)
    @product_with_ugly_description = scc_products(:two)
    @product_with_normal_description = scc_products(:three)
  end

  test 'create' do
    assert @product.save
    assert_not_empty SccProduct.where(id: @product.id)
  end

  test 'uniq_name' do
    assert_equal('111 number one', @product.uniq_name)
  end

  test 'pretty_name' do
    assert_equal('number one (id: 111)', @product.pretty_name)
  end

  test 'pretty_description' do
    assert_equal @product_with_normal_description.description,
      @product_with_normal_description.pretty_description
    assert_equal('lorem ipsum dolor sit amet', @product.pretty_description)
    assert_equal('lorem ipsum dolor sit amet', @product_with_ugly_description.pretty_description)
  end
end

class SccProductSearchTest < ActiveSupport::TestCase
  test 'default ordered by name' do
    product_names = %w[one two three
                       p_ext_1 p_ext_10 p_ext_2 p_ext_3
                       p_ext_4 p_ext_5 p_ext_6 p_ext_7
                       p_ext_8 p_ext_9]
    assert_equal SccProduct.all.pluck(:name), product_names.sort
  end

  test 'search name' do
    one = scc_products(:one)
    products = SccProduct.search_for("name = \"#{one.name}\"")
    assert_includes products, one
    assert_not_includes products, scc_products(:two)

    empty = SccProduct.search_for('name = "nothing"')
    assert_empty empty
  end
end

# These produt extension tests are pre-tests for the class ProductEmptyRepoAvailableTests.
# They do not test any direct functionality of the plugin.
class SccProductExtensionsTest < ActiveSupport::TestCase
  def setup
    @product_with_extensions = scc_products(:one)
    @product_with_extensions.scc_extensions = scc_products.select { |p| p.product_type == 'extension' }
    @product_with_wrong_extensions = scc_products(:two)
    @product_with_wrong_extensions.scc_extensions = [scc_products(:three)]
    @product_without_extensions = scc_products(:three)
  end

  test 'check product extensions available' do
    assert_equal(10, @product_with_extensions.scc_extensions.count)
    assert_not_empty @product_with_extensions.scc_extensions
    assert_empty @product_without_extensions.scc_extensions
  end

  test 'product extension of correct type' do
    assert_empty(@product_with_extensions.scc_extensions.reject { |p| p.product_type == 'extension' })
    assert_not_empty(@product_with_wrong_extensions.scc_extensions.reject { |p| p.product_type == 'extension' })
  end
end

class SccProductEmptyRepoAvailableTest < ActiveSupport::TestCase
  def setup
    @product_with_repos = scc_products(:one)
    @product_with_repos.scc_extensions = scc_products.select { |p| p.product_type == 'extension' }
    @product_with_repos.scc_repositories = scc_repositories[0..2]
    @product_with_repos.scc_extensions[1].scc_repositories = scc_repositories[3..4]
    @product_with_repos.scc_extensions[2].scc_repositories = scc_repositories[5..7]
  end

  test 'products with empty repositories' do
    products_with_repos = SccProduct.only_products_with_repos
    assert_equal(3, SccProduct.all.count { |prod| !prod.scc_repositories.empty? })
    assert_equal(3, products_with_repos.count)
  end
end

class SccProductNoRepoTest < ActiveSupport::TestCase
  def setup
    @product_with_repos = scc_products(:one)
    @product_with_repos.scc_extensions = scc_products.select { |p| p.product_type == 'extension' }
  end

  test 'products without any repositories' do
    products_with_repos = SccProduct.only_products_with_repos
    assert_empty products_with_repos
  end
end
