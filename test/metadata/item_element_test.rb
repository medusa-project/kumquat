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

  # tsv_string_from_elements()

  test 'tsv_string_from_elements() should raise an error if given elements with multiple names' do
    elements = [
        ItemElement.new(name: 'title', value: 'cats1'),
        ItemElement.new(name: 'subject', value: 'cats2')
    ]
    assert_raises ArgumentError do
      ItemElement.tsv_string_from_elements(elements)
    end
  end

  test 'tsv_string_from_elements() should return the correct string' do
    elements = [
        ItemElement.new(name: 'subject', value: 'cats',
                        uri: 'http://example.org/cats',
                        vocabulary: vocabularies(:lcsh)),
        ItemElement.new(name: 'subject', value: 'dogs',
                        vocabulary: vocabularies(:uncontrolled)),
        ItemElement.new(name: 'subject', value: 'foxes'),
        ItemElement.new(name: 'subject', uri: 'http://example.org/lions')
    ]
    assert_equal 'lcsh:cats&&<http://example.org/cats>||dogs||foxes||<http://example.org/lions>',
                 ItemElement.tsv_string_from_elements(elements)
  end

  # formatted_value()

  test 'formatted_value should return the correct value' do
    e = ItemElement.new
    e.name = 'cats'
    e.value = 'bla'
    assert_equal 'bla', e.formatted_value

    # latitude
    e = ItemElement.new
    e.name = 'latitude'
    e.value = '45.24'
    assert_equal '45.24°N', e.formatted_value
    e.value = '-45.24'
    assert_equal '45.24°S', e.formatted_value

    e = ItemElement.new
    e.name = 'longitude'
    e.value = '45.24'
    assert_equal '45.24°E', e.formatted_value
    e.value = '-45.24'
    assert_equal '45.24°W', e.formatted_value
  end

end
