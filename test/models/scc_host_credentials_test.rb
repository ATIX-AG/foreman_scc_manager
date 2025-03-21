require 'test_plugin_helper'

class SccHostCredentialsTest < ActiveSupport::TestCase
  def setup
    @host = FactoryBot.create(:host)
    @credentials = FactoryBot.create(:scc_host_credentials, host: @host)
  end

  context 'without host' do
    test 'fail create due to missing host' do
      @credentials.host = nil
      assert_raises ActiveRecord::RecordInvalid do
        @credentials.save!
      end
    end
  end

  context 'with host' do
    test 'create' do
      assert @credentials.save
      assert_not_empty SccHostCredentials.where(:id => @credentials.id)
    end

    test 'destroy' do
      credentials_id = @credentials.id
      assert @credentials.destroy
      assert_empty SccHostCredentials.where(:id => credentials_id)
    end

    test 'host-dependent destroy' do
      credentials_id = @credentials.id
      assert @host.destroy
      assert_empty SccHostCredentials.where(:id => credentials_id)
    end

    test 'host relation' do
      second_host = FactoryBot.create(:host)
      assert_equal @credentials.host.id, @host.id
      assert @credentials.host = second_host
      assert @credentials.save
      assert_equal @credentials.host.id, second_host.id
      assert_nil @host.scc_host_credentials
    end

    test 'password is saved encrypted when updated' do
      assert SccHostCredentials.encrypts? :scc_password
      @credentials.expects(:encryption_key).at_least_once.returns('25d224dd383e92a7e0c82b8bf7c985e815f34cf5')
      @credentials.scc_password = '123456'
      as_admin do
        assert @credentials.save
      end
      assert_equal @credentials.scc_password, '123456'
      assert_not_equal @credentials.scc_password_in_db, '123456'
    end
  end
end
