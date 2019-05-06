require 'test_plugin_helper'

class SccAccountCreateTest < ActiveSupport::TestCase
  def setup
    @account = scc_accounts(:one)
  end

  test 'create' do
    assert @account.save
    refute_empty SccAccount.where(:id => @account.id)
  end

  test 'create default url' do
    account = scc_accounts(:account_missing_url)
    assert account.save
    assert_equal account.base_url, 'https://scc.suse.com'
    refute_empty SccAccount.where(:id => @account.id)
  end

  test 'create missing value' do
    list = {
      name: 'Not Working',
      organization: get_organization,
      # base_url has a default value set in DB
      # base_url: 'https://scc.example.org',
      login: 'account1',
      password: 'secret'
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
    assert_equal @account.password, '123456'
    refute_equal @account.password_in_db, '123456'
  end
end

class SccAccountSearchTest < ActiveSupport::TestCase
  test 'default ordered by login' do
    assert_equal SccAccount.all.pluck(:login), ['oneuser', 'twouser', 'fakeuser1'].sort
  end

  test 'search login' do
    one = scc_accounts(:one)
    accounts = SccAccount.search_for("login = \"#{one.login}\"")
    assert_includes accounts, one
    refute_includes accounts, scc_accounts(:two)

    empty = SccAccount.search_for('login = "nobody"')
    assert_empty empty
  end
end

# FIXME: test cascaded delete
