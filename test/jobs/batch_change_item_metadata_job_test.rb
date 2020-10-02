require 'test_helper'

class BatchChangeItemMetadataJobTest < ActiveSupport::TestCase

  # perform()

  test 'perform() should change all matching elements in a collection' do
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

    BatchChangeItemMetadataJob.perform_now(col, element_name, new_values)

    col.items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

  test 'perform() should change all matching elements in an ItemSet' do
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

    BatchChangeItemMetadataJob.perform_now(set, element_name, new_values)

    set.items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

  test 'perform() should change all matching elements in an Enumerable of
  Items' do
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

    BatchChangeItemMetadataJob.perform_now(items, element_name, new_values)

    items.each do |item|
      titles = item.elements.select{ |e| e.name == 'title' }
      assert_equal new_values.length, titles.length
      new_values.each do |nv|
        assert_equal 1, titles.select{ |e| e.value == nv[:string] and e.uri == nv[:uri] }.length
      end
    end
  end

end
