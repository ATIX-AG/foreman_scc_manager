require 'test_plugin_helper'

class SccHostCredentialsTest < ActiveSupport::TestCase
  def setup
    @host = FactoryBot.create(:host)
    @facet = @host.create_scc_facet
    @credentials = FactoryBot.create(:scc_host_credentials, scc_facet: @facet)
  end

  context 'without facet' do
    test 'fail create due to missing facet' do
      @credentials.scc_facet = nil
      assert_raises ActiveRecord::RecordInvalid do
        @credentials.save!
      end
    end
  end

  context 'with facet' do
    test 'create' do
      assert @credentials.save
      assert_not_empty SccHostCredentials.where(id: @credentials.id)
    end

    test 'destroy' do
      credentials_id = @credentials.id
      assert @credentials.destroy
      assert_empty SccHostCredentials.where(id: credentials_id)
    end

    test 'facet-dependent destroy' do
      credentials_id = @credentials.id
      assert @facet.destroy
      assert_empty SccHostCredentials.where(id: credentials_id)
    end

    test 'facet relation' do
      assert_equal @credentials.scc_facet.id, @facet.id
      assert_equal @facet.scc_host_credentials.id, @credentials.id
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
