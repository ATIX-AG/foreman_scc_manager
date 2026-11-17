require 'test_plugin_helper'

class Api::V2::SccHostsControllerTest < ActionController::TestCase
  def setup
    @host_with_credentials = FactoryBot.create(:host, :with_scc_host_credentials)
    @host_without_credentials = FactoryBot.create(:host)
  end

  test 'index returns all hosts with registration status' do
    get :index
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('results')
    # registered host shows registered: true, unregistered shows false
  end

  test 'index filters to registered hosts with scoped search' do
    get :index, params: { search: 'set? scc_registered' }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    ids = body['results'].map { |h| h['id'] }
    assert_includes ids, @host_with_credentials.id
    assert_not_includes ids, @host_without_credentials.id
  end

  test 'index filters to unregistered hosts' do
    get :index, params: { search: 'null? scc_registered' }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    ids = body['results'].map { |h| h['id'] }
    assert_includes ids, @host_without_credentials.id
    assert_not_includes ids, @host_with_credentials.id
  end

  test 'show returns registered true for a host with credentials' do
    get :show, params: { id: @host_with_credentials.id }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert body['registered']
    assert_nil body['scc_login']
  end

  test 'show returns registered false for a host without credentials' do
    get :show, params: { id: @host_without_credentials.id }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert_not body['registered']
  end

  test 'show 404 for unknown host' do
    get :show, params: { id: 'does-not-exist' }
    assert_response :not_found
  end

  test 'update starts announcement task with valid reg_code' do
    ::ForemanTasks.expects(:async_task)
                  .with(::Actions::SccManager::GetSccHostCredentials,
                    ::SccManager.build_host_payload(@host_without_credentials),
                    @host_without_credentials.id,
                    'dummy-reg-code')
                  .returns(ForemanTasks::Task::DynflowTask.new)

    put :update, params: { id: @host_without_credentials.id, reg_code: 'dummy-reg-code' }
    assert_response :accepted
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('task_id')
  end

  test 'update fails with blank reg_code' do
    put :update, params: { id: @host_without_credentials.id, reg_code: '' }
    assert_response :unprocessable_entity
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('error')
  end

  test 'update does not announce a host that is already registered' do
    ::ForemanTasks.expects(:async_task).never

    put :update, params: { id: @host_with_credentials.id, reg_code: 'dummy-reg-code' }
    assert_response :success
    body = ActiveSupport::JSON.decode(@response.body)
    assert body['registered']
  end

  test 'update fails with missing reg_code' do
    put :update, params: { id: @host_without_credentials.id }
    assert_response :unprocessable_entity
  end

  test 'destroy starts deregistration task for a registered host' do
    credentials_id = @host_with_credentials.scc_host_credentials.id
    ::ForemanTasks.expects(:async_task)
                  .with(::Actions::SccManager::DeregisterHostFromScc, credentials_id)
                  .returns(ForemanTasks::Task::DynflowTask.new)

    delete :destroy, params: { id: @host_with_credentials.id }
    assert_response :accepted
    body = ActiveSupport::JSON.decode(@response.body)
    assert body.key?('task_id')
  end

  test 'destroy returns not_found for a host without credentials' do
    delete :destroy, params: { id: @host_without_credentials.id }
    assert_response :not_found
  end

  test 'index with registered=true returns only registered hosts' do
    get :index, params: { registered: true }
    assert_response :success
    ids = ActiveSupport::JSON.decode(@response.body)['results'].map { |h| h['id'] }
    assert_includes ids, @host_with_credentials.id
    assert_not_includes ids, @host_without_credentials.id
  end

  test 'index with registered=false returns only unregistered hosts' do
    get :index, params: { registered: false }
    assert_response :success
    ids = ActiveSupport::JSON.decode(@response.body)['results'].map { |h| h['id'] }
    assert_includes ids, @host_without_credentials.id
    assert_not_includes ids, @host_with_credentials.id
  end

  test 'index combines registered with search' do
    get :index, params: { registered: true, search: "name = \"#{@host_with_credentials.name}\"" }
    assert_response :success
    ids = ActiveSupport::JSON.decode(@response.body)['results'].map { |h| h['id'] }
    assert_equal [@host_with_credentials.id], ids
  end
end
