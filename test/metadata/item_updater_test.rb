require 'test_helper'

class ItemUpdaterTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @instance = ItemUpdater.new
  end

  # change_element_values()

  test 'change_element_values() should work' do
    items = collections(:compound_object).items

    item = items(:compound_object_1002_page1)
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
    items = collections(:compound_object).items

    test_item = items(:compound_object_1001)
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
    items = collections(:compound_object).items

    # Test match
    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'title', value: 'required')
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'foxes', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'tigers', item.element(:cat).value
  end

  test 'replace_element_values() should work with :exact_match matching
  mode and :matched_part replace mode' do
    items = collections(:compound_object).items

    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :exact_match, 'ZZZtigersZZZ',
                                     'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value
  end

  test 'replace_element_values() should work with :contain matching mode
  and :whole_value replace mode' do
    items = collections(:compound_object).items

    # Test match
    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'title', value: 'required')
    item.elements.build(name: 'cat', value: 'foxes')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'foxes', item.element(:cat).value
  end

  test 'replace_element_values() should work with :contain matching mode
  and :matched_part replace mode' do
    items = collections(:compound_object).items

    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @instance.replace_element_values(items, :contain, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlionsZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with :start matching mode and
  :whole_value replace mode' do
    items = collections(:compound_object).items

    # Test match
    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'title', value: 'required')
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'ZZZtigers', item.element(:cat).value
  end

  test 'replace_element_values() should work with :start matching mode and
  :matched_part replace mode' do
    items = collections(:compound_object).items

    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :start, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'lionsZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with :end matching mode and
  :whole_value replace mode' do
    items = collections(:compound_object).items

    # Test match
    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'title', value: 'required')
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :whole_value, 'lions')

    item.reload
    assert_equal 'tigersZZZ', item.element(:cat).value
  end

  test 'replace_element_values() should work with end matching mode and
  matched_part replace mode' do
    items = collections(:compound_object).items

    item = items(:compound_object_1002_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @instance.replace_element_values(items, :end, 'tigers', 'cat',
                                     :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlions', item.element(:cat).value
  end

  # update_from_embedded_metadata()

  test 'update_from_embedded_metadata() updates items from embedded metadata' do
    skip # TODO: add an image with embedded metadata into Mockdusa
    collection = collections(:free_form)
    @instance.update_from_embedded_metadata(collection: collection)
    item_count    = 0
    element_count = 0
    collection.items.each do |item|
      item_count    += 1
      element_count += item.elements.count
    end
    assert element_count > item_count
  end

  test 'update_from_embedded_metadata() respects the include_date_created
  argument' do
    skip # TODO: add an image with embedded metadata into Mockdusa
    collection = collections(:compound_object)
    @instance.update_from_embedded_metadata(collection: collection)
    count_without_date = 0
    collection.items.each do |item|
      count_without_date += item.elements.count
    end

    @instance.update_from_embedded_metadata(collection:           collection,
                                            include_date_created: true)
    count_with_date = 0
    collection.items.each do |item|
      count_with_date += item.elements.count
    end
    assert count_with_date > count_without_date
  end

  # update_from_tsv()

  test 'update_from_tsv() updates items from valid TSV' do
    Item.destroy_all
    tsv_pathname = File.join(Rails.root, 'test', 'fixtures', 'repository',
                             'compound_object.tsv')

    # Create the items
    tsv = File.read(tsv_pathname)
    CSV.parse(tsv,
              headers: true,
              col_sep: "\t",
              quote_char: "\x00").map(&:to_hash).each do |row|
      item = Item.new(repository_id: row['uuid'],
                      collection_repository_id: collections(:compound_object).repository_id)
      item.elements.build(name: "title", value: row['Title'])
      item.save!
    end

    assert_equal 2, @instance.update_from_tsv(tsv_pathname)

    # Check their metadata
    assert_equal 'New Title From TSV',
                 Item.find_by_repository_id('21353276-887c-0f2b-25a0-ed444003303f').title
  end

  test 'update_from_tsv() does not add unnecessary quotes' do
    Item.destroy_all
    tsv_pathname = File.join(Rails.root, 'test', 'fixtures', 'repository',
                             'quotes.tsv')

    # Create the items
    tsv = File.read(tsv_pathname)
    CSV.parse(tsv,
              headers:         true,
              col_sep:         "\t",
              quote_char:      "\x00",
              liberal_parsing: true).map(&:to_hash).each do |row|
      item = Item.new(repository_id: row['uuid'],
                      collection_repository_id: collections(:compound_object).repository_id)
      item.elements.build(name: "title", value: row['Title'])
      item.save!
    end

    assert_equal 2, @instance.update_from_tsv(tsv_pathname)

    assert_equal '"This title has quotes"',
                 Item.find_by_repository_id('21353276-887c-0f2b-25a0-ed444003303f').title
    assert_equal '""This title has double quotes""',
                 Item.find_by_repository_id('8ec70c33-75c9-4ba5-cd21-54a1211e5375').title
  end

  # validate_tsv_header()

  test "validate_tsv_header() returns true for a valid header" do
    tsv_pathname = File.join(Rails.root, 'test', 'fixtures', 'repository',
                             'compound_object.tsv')
    assert @instance.validate_tsv(pathname:         tsv_pathname,
                                  metadata_profile: metadata_profiles(:compound_object))
  end

  test "validate_tsv_header() returns false for an invalid header" do
    tsv_pathname = File.join(Rails.root, 'test', 'fixtures', 'repository',
                             'compound_object.tsv')
    assert_raises ArgumentError do
      @instance.validate_tsv(pathname:         tsv_pathname,
                             metadata_profile: metadata_profiles(:unused))
    end
  end

end
