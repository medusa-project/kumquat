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
