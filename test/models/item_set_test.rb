require 'test_helper'

class ItemSetTest < ActiveSupport::TestCase

  setup do
    @instance = item_sets(:one)
  end

  test 'add_item() adds an item' do
    @instance.items.clear
    item = items(:compound_object_1001)
    @instance.add_item(item)

    assert_equal 1, @instance.items.count
  end

  test 'add_item() silently discards duplicate items' do
    @instance.items.clear
    item = items(:compound_object_1001)
    @instance.add_item(item)
    @instance.add_item(item)

    assert_equal 1, @instance.items.count
  end

  test 'add_item_and_children() works' do
    @instance.items.clear
    item = items(:compound_object_1001)
    @instance.add_item_and_children(item)

    assert_equal item.all_children.length + 1, @instance.items.count
  end

  test 'add_item_and_children() silently discards duplicate items' do
    @instance.items.clear
    item = items(:compound_object_1001)
    @instance.add_item_and_children(item)
    @instance.add_item_and_children(item)

    assert_equal item.all_children.length + 1, @instance.items.count
  end

end
