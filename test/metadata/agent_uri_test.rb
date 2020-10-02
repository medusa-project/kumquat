require 'test_helper'

class AgentUriTest < ActiveSupport::TestCase

  # create()

  test 'create() creates a corresponding vocabulary term' do
    uri = 'http://example.biz/cats'
    assert_nil VocabularyTerm.find_by_uri(uri)
    AgentUri.create!(agent: agents(:one), uri: uri)
    assert_not_nil VocabularyTerm.find_by_uri(uri)
  end

  # destroy()

  test 'destroy() updates the corresponding vocabulary term' do
    uri = 'http://example.biz/cats'
    assert_nil VocabularyTerm.find_by_uri(uri)
    agent_uri = AgentUri.create!(agent: agents(:one), uri: uri)
    assert_not_nil VocabularyTerm.find_by_uri(uri)
    agent_uri.destroy!
    assert_nil VocabularyTerm.find_by_uri(uri)
  end

  # save()

  test 'save() on an existing instance updates the corresponding vocabulary term' do
    uri1 = 'http://example.biz/cats'
    uri2 = 'http://example.biz/dogs'

    agent_uri = AgentUri.create!(agent: agents(:one), uri: uri1)

    agent_uri.uri = uri2
    agent_uri.save!

    assert_nil VocabularyTerm.find_by_uri(uri1)
    assert_not_nil VocabularyTerm.find_by_uri(uri2)
  end

end
