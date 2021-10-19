# frozen_string_literal: true

require 'test_plugin_helper'

class SccAccountCreateTest < ActiveSupport::TestCase
  def setup
    @account = scc_accounts(:one)
  end

  test 'create' do
    assert @account.save
    assert_not_empty SccAccount.where(id: @account.id)
  end

  test 'create default url' do
    account = scc_accounts(:account_missing_url)
    assert account.save
    assert_equal('https://scc.suse.com', account.base_url)
    assert_not_empty SccAccount.where(id: @account.id)
  end

  test 'create missing value' do
    list = {
      name: 'Not Working',
      organization: get_organization,
      # base_url has a default value set in DB
      # base_url: 'https://scc.example.org',
      login: 'account1',
      password: 'secret',
    }

    # for every key in hash try to create account without it set
    list.each_key do |k|
      l = list.clone
      l.delete(k)
      assert_raises ActiveRecord::RecordInvalid do
        SccAccount.new(l).save!
      end
    end
  end

  test 'create wrong interval-value' do
    account = scc_accounts(:two)
    account.interval = 'gazillion'
    assert_not account.save
  end

  test 'password is saved encrypted when updated' do
    assert SccAccount.encrypts? :password
    @account.expects(:encryption_key).at_least_once.returns('25d224dd383e92a7e0c82b8bf7c985e815f34cf5')
    @account.password = '123456'
    as_admin do
      assert @account.save
    end
    assert_equal('123456', @account.password)
    assert_not_equal @account.password_in_db, '123456'
  end
end

class SccAccountSearchTest < ActiveSupport::TestCase
  test 'default ordered by login' do
    assert_equal SccAccount.all.pluck(:login), %w[oneuser twouser fakeuser1].sort
  end

  test 'search login' do
    one = scc_accounts(:one)
    accounts = SccAccount.search_for("login = \"#{one.login}\"")
    assert_includes accounts, one
    assert_not_includes accounts, scc_accounts(:two)

    empty = SccAccount.search_for('login = "nobody"')
    assert_empty empty
  end
end

class SccAccountUpdateProductsTest < ActiveSupport::TestCase
  def setup
    @account = scc_accounts(:one)
    one = scc_products(:one)
    @account.scc_products = SccProduct.where(name: 'one')
    # generate test data, beware that hash names are not equal to SccProduct instance names
    @product_data = { 'name' => one.name,
                      'id' => one.scc_id,
                      'version' => one.version,
                      'arch' => one.arch,
                      'repositories' => one.scc_repositories,
                      'extensions' => one.scc_extensions,
                      'product_type' => one.product_type,
                      'description' => '<p> new unpretty description </p>',
                      'friendly_name' => 'updated name' }
    @product_array = []
    @product_array.push @product_data

    @test_product = SccProduct.new
    @test_product.scc_id = @product_data['id']
    @test_product.friendly_name = @product_data['friendly_name']
    @test_product.description = @product_data['description']
  end

  test 'update scc product' do
    @account.update_scc_products(@product_array)
    @updated_product = @account.scc_products.where(friendly_name: 'updated name').first
    assert_equal @test_product.pretty_name, @updated_product.name
    assert_equal @test_product.pretty_name, @updated_product.pretty_name
    assert_equal @test_product.pretty_description, @updated_product.description
    assert_equal @test_product.pretty_description, @updated_product.pretty_description

    assert @updated_product.subscription_valid
    @invalid_products = @account.scc_products.where.not(scc_id: scc_products(:one).scc_id)
    @invalid_products.each do |ip|
      assert_not ip.subscription_valid
    end
  end
end

class SccAccountUpdateReposTest < ActiveSupport::TestCase
  def setup
    @account = scc_accounts(:one)
    test_repo = scc_repositories(:repo_9)
    @account.scc_repositories = SccProduct.where(name: 'repo_9')
    # generate test data
    @repo_data = { 'name' => test_repo.name,
                   'id' => test_repo.scc_id,
                   'distro_target' => test_repo.distro_target,
                   'url' => test_repo.url,
                   'enabled' => test_repo.enabled,
                   'autorefresh' => test_repo.autorefresh,
                   'installer_updates' => test_repo.installer_updates,
                   'description' => '<p> new unpretty repo description </p>' }
    @repo_array = []
    @repo_array.push @repo_data

    @test_repo = SccRepository.new
    @test_repo.description = @repo_data['description']
    @test_repo.name = @repo_data['name']
  end

  test 'update scc repository' do
    @account.update_scc_repositories(@repo_array)
    @updated_repo = @account.scc_repositories.where(name: @test_repo.pretty_name).first
    assert_equal @test_repo.pretty_name, @updated_repo.name
    assert_equal @test_repo.pretty_name, @updated_repo.pretty_name
  end
end

# FIXME: test cascaded delete
