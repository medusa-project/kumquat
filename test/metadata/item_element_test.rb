require 'test_helper'

class ItemElementTest < ActiveSupport::TestCase

  test '== should work properly' do
    # same properties
    e1 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    assert e1 == e2

    # different names
    e1 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = ItemElement.new(name: 'name2', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    assert e1 != e2

    # different values
    e1 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = ItemElement.new(name: 'name1', value: 'value2', uri: 'http://1', vocabulary_id: 1)
    assert e1 != e2

    # different URIs
    e1 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = ItemElement.new(name: 'name1', value: 'value1', uri: 'http://2', vocabulary_id: 1)
    assert e1 != e2

    # different vocabulary IDs
    e1 = ItemElement.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = ItemElement.new(name: 'name1', value: 'value1', vocabulary_id: 2)
    assert e1 != e2
  end

  # elements_from_tsv_string()

  test 'elements_from_tsv_string() should raise an error if given an invalid element name' do
    assert_raises ArgumentError do
      ItemElement.elements_from_tsv_string('bogus', 'cats')
    end
  end

  test 'elements_from_tsv_string() should return the correct elements' do
    # single string value
    elements = ItemElement.elements_from_tsv_string('title', 'cats')
    assert_equal 1, elements.length
    assert_equal ItemElement.new(name: 'title', value: 'cats',
                                 vocabulary: Vocabulary::uncontrolled), elements[0]

    # kitchen sink
    elements = ItemElement.elements_from_tsv_string(
        'title', "cats&&<http://example.org/cats>||lcsh:dogs&&<http://example.org/dogs>")
    assert_equal 2, elements.length
    assert_equal ItemElement.new(name: 'title', value: 'cats',
                                 vocabulary: vocabularies(:uncontrolled),
                                 uri: 'http://example.org/cats'), elements[0]
    assert_equal ItemElement.new(name: 'title', value: 'dogs',
                                 vocabulary: vocabularies(:lcsh),
                                 uri: 'http://example.org/dogs'), elements[1]
  end

end
