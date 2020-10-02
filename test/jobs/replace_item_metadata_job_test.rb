require 'test_helper'

class ReplaceItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  ##
  # This is just a basic test that perform() does something and returns.
  # The test of ItemUpdater.new.replace_element_values() is tested more
  # thoroughly in ItemUpdaterTest.
  #
  test 'perform() should work when given a Collection' do
    col = collections(:free_form)
    assert col.items.count > 0

    col.items.each do |item|
      item.elements.build(name: 'title', value: 'cats')
      item.save!
    end

    ReplaceItemMetadataJob.perform_now(col, :exact_match, 'cats', 'title',
                                       :whole_value, 'dogs')

    col.items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == 'title' and e.value == 'cats' }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == 'title' and e.value == 'dogs' }.length
    end
  end

  ##
  # This is just a basic test that perform() does something and returns.
  # The test of ItemUpdater.new.replace_element_values() is tested more
  # thoroughly in ItemUpdaterTest.
  #
  test 'perform() should work when given an ItemSet' do
    set = item_sets(:one)
    assert set.items.count > 0

    set.items.each do |item|
      item.elements.build(name: 'title', value: 'cats')
      item.save!
    end

    ReplaceItemMetadataJob.perform_now(set, :exact_match, 'cats', 'title',
                                       :whole_value, 'dogs')

    set.items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == 'title' and e.value == 'cats' }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == 'title' and e.value == 'dogs' }.length
    end
  end

  ##
  # This is just a basic test that perform() does something and returns.
  # The test of ItemUpdater.new.replace_element_values() is tested more
  # thoroughly in ItemUpdaterTest.
  #
  test 'perform() should work when given an Enumerable of Items' do
    items = collections(:compound_object).items
    assert items.count > 0

    items.each do |item|
      item.elements.build(name: 'title', value: 'cats')
      item.save!
    end

    ReplaceItemMetadataJob.perform_now(items, :exact_match, 'cats', 'title',
                                       :whole_value, 'dogs')

    items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == 'title' and e.value == 'cats' }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == 'title' and e.value == 'dogs' }.length
    end
  end

end
