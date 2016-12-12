require 'test_helper'

class EntityElementTest < ActiveSupport::TestCase

  # agent()

  test 'agent() should return an agent' do
    uri = agent_uris(:one).uri
    e = EntityElement.new(name: 'whatever', uri: uri)
    assert_equal agent_uris(:one).uri, e.agent.primary_uri
  end

  # tsv_string_from_elements()

  test 'tsv_string_from_elements() should raise an error if given elements with multiple names' do
    elements = [
        EntityElement.new(name: 'title', value: 'cats1'),
        EntityElement.new(name: 'subject', value: 'cats2')
    ]
    assert_raises ArgumentError do
      EntityElement.tsv_string_from_elements(elements)
    end
  end

  test 'tsv_string_from_elements() should return the correct string' do
    elements = [
        EntityElement.new(name: 'subject', value: 'cats',
                        uri: 'http://example.org/cats',
                        vocabulary: vocabularies(:lcsh)),
        EntityElement.new(name: 'subject', value: 'dogs',
                        vocabulary: vocabularies(:uncontrolled)),
        EntityElement.new(name: 'subject', value: 'foxes'),
        EntityElement.new(name: 'subject', uri: 'http://example.org/lions')
    ]
    assert_equal 'lcsh:cats&&<http://example.org/cats>||dogs||foxes||<http://example.org/lions>',
                 EntityElement.tsv_string_from_elements(elements)
  end

end
