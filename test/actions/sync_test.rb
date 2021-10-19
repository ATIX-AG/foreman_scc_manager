require 'test_plugin_helper'

class SccManagerActions < ActiveSupport::TestCase
  include Dynflow::Testing

  let(:action_class) { ::Actions::SccManager::Sync }

  def setup
    @scc_account = scc_accounts(:one)
    # ensure we have an org label
    get_organization
  end

  test 'plan sync action' do
    action = create_action(action_class)
    action.stubs(:action_subject).with(@scc_account)

    assert_respond_to action, :phase
    plan_action(action, @scc_account)

    assert_action_planned_with(action, ::Actions::SccManager::SyncProducts, @scc_account)
    assert_action_planned_with(action, ::Actions::SccManager::SyncRepositories, @scc_account)
  end
end
