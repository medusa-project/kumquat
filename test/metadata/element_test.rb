require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  test '== should work properly' do
    # same properties
    e1 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    assert e1 == e2

    # different names
    e1 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = Element.new(name: 'name2', value: 'value1', vocabulary_id: 1)
    assert e1 != e2

    # different values
    e1 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = Element.new(name: 'name1', value: 'value2', vocabulary_id: 1)
    assert e1 != e2

    # different vocabulary IDs
    e1 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = Element.new(name: 'name1', value: 'value1', vocabulary_id: 2)
    assert e1 != e2
  end

  test 'formatted_value should return the correct value' do
    e = Element.new
    e.name = 'cats'
    e.value = 'bla'
    assert_equal 'bla', e.formatted_value

    # latitude
    e = Element.new
    e.name = 'latitude'
    e.value = '45.24'
    assert_equal '45.24°N', e.formatted_value
    e.value = '-45.24'
    assert_equal '45.24°S', e.formatted_value

    e = Element.new
    e.name = 'longitude'
    e.value = '45.24'
    assert_equal '45.24°E', e.formatted_value
    e.value = '-45.24'
    assert_equal '45.24°W', e.formatted_value
  end

end
