require 'test_helper'

class MigrateItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should work with a Collection argument' do
    col = collections(:free_form)
    assert col.items.count > 0

    src_element_name  = 'old_bogus'
    dest_element_name = 'new_bogus'

    col.items.each do |item|
      item.elements.build(name: src_element_name, value: 'cats')
      item.save!
    end

    MigrateItemMetadataJob.perform_now(collection:     col,
                                       source_element: src_element_name,
                                       dest_element:   dest_element_name)

    col.items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == src_element_name }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == dest_element_name }.length
    end
  end

  test 'perform() should work with an ItemSet argument' do
    set = item_sets(:one)
    assert set.items.count > 0

    src_element_name  = 'old_bogus'
    dest_element_name = 'new_bogus'

    set.items.each do |item|
      item.elements.build(name: src_element_name, value: 'cats')
      item.save!
    end

    MigrateItemMetadataJob.perform_now(item_set:       set,
                                       source_element: src_element_name,
                                       dest_element:   dest_element_name)

    set.items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == src_element_name }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == dest_element_name }.length
    end
  end

  test 'perform() should work with an Enumerable of Items argument' do
    items = collections(:free_form).items
    assert items.count > 0

    src_element_name  = 'old_bogus'
    dest_element_name = 'new_bogus'

    items.each do |item|
      item.elements.build(name: src_element_name, value: 'cats')
      item.save!
    end

    MigrateItemMetadataJob.perform_now(item_ids:       items.map(&:repository_id),
                                       source_element: src_element_name,
                                       dest_element:   dest_element_name)

    items.each do |item|
      item.reload
      assert_equal 0, item.elements.
          select{ |e| e.name == src_element_name }.length
      assert_equal 1, item.elements.
          select{ |e| e.name == dest_element_name }.length
    end
  end

end
