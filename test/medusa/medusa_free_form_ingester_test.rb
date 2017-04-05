require 'test_helper'

class MedusaFreeFormIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaFreeFormIngester.new

    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() should return nil with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/414021.json
    item = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_nil MedusaFreeFormIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() should return the parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_directories/111150.json
    page = 'a536b060-5ca8-0132-3334-0050569601ca-8'
    # https://medusa.library.illinois.edu/cfs_directories/111144.json
    expected_parent = 'a53194a0-5ca8-0132-3334-0050569601ca-8'
    assert_equal expected_parent,
                 MedusaFreeFormIngester.parent_id_from_medusa(page)
  end

  # create_items()

  test 'create_items() with collection file group not set should raise an error' do
    collection = collections(:collection1)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items() with collection package profile not set should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items() with collection package profile set incorrectly should
  raise an error' do
    collection = collections(:collection1)
    collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items() should work' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = 'a53add10-5ca8-0132-3334-0050569601ca-7'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_free_form_tree.json'))
    # Extract a small slice of the tree.
    tree = tree['subdirectories'][0]
    tree['subdirectories'] = tree['subdirectories'][0..0]
    tree['subdirectories'][0]['files'] =
        tree['subdirectories'][0]['files'][0..1]
    cfs_dir.json_tree = tree

    # Run the ingest.
    result = @instance.create_items(collection)

    # Assert that the correct number of items were added.
    assert_equal 3, Item.count
    assert_equal 3, result[:num_created]
    assert_equal 0, result[:num_skipped]
    assert_equal 3, result[:num_walked]

    # Inspect an individual directory item more thoroughly.
    item = Item.find_by_repository_id('a53add10-5ca8-0132-3334-0050569601ca-7')
    #assert_equal 1, item.items.length
    assert_equal 0, item.binaries.length
    assert_equal Item::Variants::DIRECTORY, item.variant

    # Inspect an individual file item more thoroughly.
    item = Item.find_by_repository_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
    item.binaries.each do |bs|
      assert_equal Binary::MasterType::ACCESS, bs.master_type
    end
    assert_empty item.items
    assert_equal 1, item.binaries.length
    assert_equal Item::Variants::FILE, item.variant
    assert_equal 1, item.elements.length
    assert_equal 'animals_001.jpg', item.title

    bs = item.binaries.first
    assert_equal 1757527, bs.byte_size
    assert_equal 'image/jpeg', bs.media_type
    assert_equal Binary::MediaCategory::IMAGE, bs.media_category
    assert_equal '/136/310/3707005/access/online/Illini_Union_Photographs/binder_10/animals/animals_001.jpg',
                 bs.repository_relative_pathname
  end

  test 'create_items() should extract metadata when told to' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = 'a53add10-5ca8-0132-3334-0050569601ca-7'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_free_form_tree.json'))
    # Extract a small slice of the tree.
    tree = tree['subdirectories'][0]['subdirectories'][0]
    tree['files'] = tree['files'][0..1]
    cfs_dir.json_tree = tree

    # Run the ingest.
    @instance.create_items(collection, extract_metadata: true)

    # Assert that the metadata was extracted.
    item = Item.find_by_repository_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
    assert item.elements.select{ |e| e.name == 'creator' }.map(&:value).
        include?('University of Illinois Library')
    assert item.elements.select{ |e| e.name == 'title' }.map(&:value).
        include?('Illini Union Photographs Record Series 3707005')
  end

  # delete_missing_items()

  test 'delete_missing_items() with collection file group not set should raise an error' do
    collection = collections(:collection1)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() with collection package profile not set should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() with collection package profile set incorrectly
  should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() should work' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..1]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.create_items(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'] = tree['subdirectories'][0..0]
    cfs_dir.json_tree = tree

    # Delete the items.
    result = @instance.delete_missing_items(collection)

    # Assert that they were deleted.
    assert_equal start_num_items - 7, Item.count
    assert_equal 7, result[:num_deleted]
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set should raise an error' do
    collection = collections(:collection1)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() with collection package profile not set should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() should work' do
    # TODO: write this
  end

  # update_binaries()

  test 'update_binaries() with collection file group not set should raise an error' do
    collection = collections(:collection1)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.update_binaries(collection)
    end
  end

  test 'update_binaries() with collection package profile not set should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.update_binaries(collection)
    end
  end

  test 'update_binaries() with collection package profile set incorrectly
  should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE

    assert_raises ArgumentError do
      @instance.update_binaries(collection)
    end
  end

  test 'update_binaries with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.update_binaries(collection)
    end
  end

  test 'update_binaries() should work' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = 'ac1a9850-0b09-0134-1d54-0050569601ca-a'
    cfs_dir = collection.effective_medusa_cfs_directory
    # Not a typo; we're treating this as a free-form tree.
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.update_binaries(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all of their binaries.
    Binary.destroy_all

    # Update binaries again.
    result = @instance.update_binaries(collection)

    # Assert that the binaries were created.
    assert_equal Binary.count, result[:num_created]
    Binary.all.each do |bs|
      assert_equal Binary::MasterType::ACCESS, bs.master_type
    end
    assert_equal start_num_items, Item.count
    assert_equal Item.where(variant: Item::Variants::FILE).count, Binary.count
    Item.where(variant: Item::Variants::FILE).each do |it|
      assert_equal 1, it.binaries.count
    end
    Item.where(variant: Item::Variants::DIRECTORY).each do |it|
      assert_empty it.binaries
    end
  end

end
