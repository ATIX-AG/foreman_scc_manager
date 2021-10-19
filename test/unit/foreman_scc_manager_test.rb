# frozen_string_literal: true

require 'test_plugin_helper'

class ForemanSccManagerTest < ActiveSupport::TestCase
  setup do
    User.current = User.find_by login: 'admin'
  end

  test 'the truth' do
    assert true
  end
end
