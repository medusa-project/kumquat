require 'test_helper'

class AgentTest < ActiveSupport::TestCase

  setup do
    @agent = agents(:one)
  end

  # primary_uri()

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

  # to_solr()

  test 'to_solr returns the correct Solr document' do
    doc = @agent.to_solr
    assert_equal @agent.solr_id, doc[Agent::SolrFields::ID]
    assert_equal @agent.class.to_s, doc[Agent::SolrFields::CLASS]
    assert_equal @agent.description, doc[Agent::SolrFields::DESCRIPTION]
    assert doc[Agent::SolrFields::EFFECTIVELY_PUBLISHED]
    assert_equal @agent.name, doc[Agent::SolrFields::NAME]
  end

end
