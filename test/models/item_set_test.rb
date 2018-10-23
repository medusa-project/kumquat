require 'test_helper'

class ItemSetTest < ActiveSupport::TestCase

  setup do
    @instance = item_sets(:sanborn)
  end

  test 'add_item_and_children() works' do
    @instance.items.clear
    item = items(:sanborn_obj1)
    @instance.add_item_and_children(item)

    assert_equal item.all_children.length + 1, @instance.items.count
  end

  test 'add_item_and_children() does not double-add items' do
    @instance.items.clear
    item = items(:sanborn_obj1)
    @instance.add_item_and_children(item)
    @instance.add_item_and_children(item)

    assert_equal item.all_children.length + 1, @instance.items.count
  end

end
