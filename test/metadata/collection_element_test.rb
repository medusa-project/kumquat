require 'test_helper'

class CollectionElementTest < ActiveSupport::TestCase

  # all_available()

  test 'all_available() returns all available elements' do
    assert_equal Element.all.length, CollectionElement.all_available.length
  end

  # named()

  test 'named() returns the corresponding element' do
    assert_not_nil CollectionElement.named('title')
  end

  test 'named() returns nil if there is no corresponding element' do
    assert_nil CollectionElement.named('bogus')
  end

  # ==()

  test '==() works properly' do
    # same properties
    e1 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    assert e1 == e2

    # different names
    e1 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = CollectionElement.new(name: 'name2', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    assert e1 != e2

    # different values
    e1 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = CollectionElement.new(name: 'name1', value: 'value2', uri: 'http://1', vocabulary_id: 1)
    assert e1 != e2

    # different URIs
    e1 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://1', vocabulary_id: 1)
    e2 = CollectionElement.new(name: 'name1', value: 'value1', uri: 'http://2', vocabulary_id: 1)
    assert e1 != e2

    # different vocabulary IDs
    e1 = CollectionElement.new(name: 'name1', value: 'value1', vocabulary_id: 1)
    e2 = CollectionElement.new(name: 'name1', value: 'value1', vocabulary_id: 2)
    assert e1 != e2
  end

end
