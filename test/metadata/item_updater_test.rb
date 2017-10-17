require 'test_helper'

class ItemUpdaterTest < ActiveSupport::TestCase

  setup do
    @instance = ItemUpdater.new
  end

  # change_element_values()

  test 'change_element_values() should work' do
    items = collections(:sanborn).items

    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tiger')
    item.elements.build(name: 'cat', value: 'leopard')
    item.save!

    @instance.change_element_values(items, 'cat', [
        { string: 'lion', uri: 'http://example.org/lion' },
        { string: 'cougar', uri: 'http://example.org/cougar' }
    ])

    item.reload
    assert_equal 2, item.elements.select{ |e| e.name == 'cat' }.length
    elements = item.elements.select{ |e| e.name == 'cat' }
    assert elements.map(&:value).include?('lion')
    assert elements.map(&:uri).include?('http://example.org/lion')
    assert elements.map(&:value).include?('cougar')
    assert elements.map(&:uri).include?('http://example.org/cougar')
  end

  # migrate_elements()

  test 'migrate_elements() should work' do
    items = collections(:sanborn).items

    test_item = items(:sanborn_obj1_page1)
    test_title = test_item.title
    assert_not_empty test_title
    assert_equal 1, test_item.elements.select{ |e| e.name == 'description' }.length

    @instance.migrate_elements(items, 'title', 'description')

    test_item.reload
    assert_empty test_item.elements.select{ |e| e.name == 'title' }
    assert_equal 2, test_item.elements.select{ |e| e.name == 'description' }.length
  end

  # replace_element_values()

  test 'replace_element_values() should work with :exact_match matching
  mode and :whole_value replace mode' do
    items = collections(:sanborn).items

    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'foxes', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'tigers', item.element(:cat).value
  end

  test 'replace_element_values() should work with :exact_match matching
  mode and :matched_part replace mode' do
    items = collections(:sanborn).items

    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'ZZZtigersZZZ',
                                     'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value
  end

  test 'replace_element_values() should work with :contain matching mode
  and :whole_value replace mode' do
    items = collections(:sanborn).items

    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'foxes')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'foxes', item.element(:cat).value
  end

  test 'replace_element_values() should work with :contain matching mode
  and :matched_part replace mode' do
    items = collections(:sanborn).items

    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlionsZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with :start matching mode and
  :whole_value replace mode' do
    items = collections(:sanborn).items

    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'ZZZtigers', item.element(:cat).value
  end

  test 'replace_element_values() should work with :start matching mode and
  :matched_part replace mode' do
    items = collections(:sanborn).items

    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'lionsZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with :end matching mode and
  :whole_value replace mode' do
    items = collections(:sanborn).items

    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'tigersZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with end matching mode and
  matched_part replace mode' do
    items = collections(:sanborn).items

    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlions', item.element(:cat).value
  end

  # update_from_tsv()

  test 'update_from_tsv() should update items from valid TSV' do
    Item.destroy_all
    tsv_pathname = __dir__ + '/../fixtures/repository/lincoln.tsv'

    # Create the items
    tsv = File.read(tsv_pathname)
    CSV.parse(tsv, headers: true, col_sep: "\t", quote_char: "\x00").
        map{ |row| row.to_hash }.each do |row|
      Item.create!(repository_id: row['uuid'],
                   collection_repository_id: '6ff23a90-95b4-0131-1105-0050569601ca-f')
    end

    assert_equal 6, @instance.update_from_tsv(tsv_pathname)

    # Check their metadata
    assert_equal 'Meserve Lincoln Photograph No. 1',
                 Item.find_by_repository_id('06639370-0b08-0134-1d55-0050569601ca-4').title
  end

end
