require 'test_helper'

class BatchChangeItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() changes all matching elements in a Collection' do
    col = collections(:free_form)
    assert col.items.count > 0

    element_name = 'title'
    new_values = [
        {
            string: 'some new title',
            uri: 'http://example.org/1'
        },
        {
            string: 'another new title',
            uri: 'http://example.org/2'
        }
    ]

    BatchChangeItemMetadataJob.perform_now(collection: col,
                                           element_name:       element_name,
                                           replacement_values: new_values)

    col.items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

  test 'perform() changes all matching elements in an ItemSet' do
    set = item_sets(:one)
    assert set.items.count > 0

    element_name = 'title'
    new_values = [
        {
            string: 'some new title',
            uri: 'http://example.org/1'
        },
        {
            string: 'another new title',
            uri: 'http://example.org/2'
        }
    ]

    BatchChangeItemMetadataJob.perform_now(item_set:           set,
                                           element_name:       element_name,
                                           replacement_values: new_values)

    set.items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

  test 'perform() changes all matching elements in a Relation of Items' do
    items = collections(:compound_object).items
    assert items.count > 0

    element_name = 'title'
    new_values = [
        {
            string: 'some new title',
            uri: 'http://example.org/1'
        },
        {
            string: 'another new title',
            uri: 'http://example.org/2'
        }
    ]

    BatchChangeItemMetadataJob.perform_now(item_ids:           items.map(&:repository_id),
                                           element_name:       element_name,
                                           replacement_values: new_values)

    items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

end
