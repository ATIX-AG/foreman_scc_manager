# This calls the main test_helper in Foreman-core
require 'test_helper'

require 'dynflow/testing'
Dynflow::Testing.logger_adapter.level = 1
require 'foreman_tasks/test_helpers'
require "#{ForemanSccManager::Engine.root}/test/support/fixtures_support"

module FixtureTestCase
  extend ActiveSupport::Concern

  included do
    extend ActiveRecord::TestFixtures

    self.use_instantiated_fixtures = false
    self.pre_loaded_fixtures = true

    ForemanSccManager::FixturesSupport.set_fixture_classes(self)

    # Fixtures are copied into a separate path to combine with Foreman fixtures. This directory
    # is kept out of version control.
    self.fixture_path = Rails.root.join('tmp/combined_fixtures/')
    FileUtils.rm_rf(self.fixture_path) if File.directory?(self.fixture_path)
    Dir.mkdir(self.fixture_path)
    FileUtils.cp(Dir.glob("#{ForemanSccManager::Engine.root}/test/fixtures/models/*"), self.fixture_path)
    FileUtils.cp(Dir.glob("#{ForemanSccManager::Engine.root}/test/fixtures/controllers/*"), self.fixture_path)
    FileUtils.cp(Dir.glob(Rails.root.join('test/fixtures/*')), self.fixture_path)
    fixtures(:all)
    fixtures_loaded = load_fixtures(ActiveRecord::Base)

    User.current = ::User.unscoped.find(fixtures_loaded['users']['admin']['id'])
  end
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include ActionDispatch::TestProcess
  include FixtureTestCase
  include ForemanTasks::TestHelpers::WithInThreadExecutor

  def get_organization(org = nil)
    saved_user = User.current
    User.current = User.unscoped.find(users(:admin).id)
    org = org.nil? ? :empty_organization : org
    organization = Organization.find(taxonomies(org.to_sym).id)
    organization.stubs(:label_not_changed).returns(true)
    organization.setup_label_from_name
    location = Location.where(name: 'Location 1').first
    organization.locations << location
    organization.save!
    User.current = saved_user
    organization
  end

  def scc_fixture_file(filename)
    File.read(File.join(ForemanSccManager::Engine.root, 'test', 'fixtures', 'files', filename))
  end
end

class ActionController::TestCase
  def set_session_user(user = :admin, org = :empty_organization)
    user = user.is_a?(User) ? user : users(user)
    org = org.is_a?(Organization) ? org : taxonomies(org)
    { :user => user.id, :expires_at => 5.minutes.from_now, :organization_id => org.id }
  end
end
