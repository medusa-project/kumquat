require 'test_helper'

class AgentTest < ActiveSupport::TestCase

  setup do
    @agent = agents(:one)
  end

  test 'primary_uri() should return the primary URI' do
    assert_equal agent_uris(:one).uri, @agent.primary_uri
  end

  test 'primary_uri() should return any URI when none are set as primary' do
    @agent.agent_uris.destroy_all
    @agent.agent_uris.build(uri: 'http://cats', primary: false)
    assert_equal 'http://cats', @agent.primary_uri
  end

  test 'primary_uri() should return nil when the agent has no URIs' do
    @agent.agent_uris.destroy_all
    assert_nil @agent.primary_uri
  end

end
