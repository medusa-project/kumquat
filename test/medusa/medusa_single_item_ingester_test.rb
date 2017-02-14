require 'test_helper'

class MedusaSingleItemIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaSingleItemIngester.new

    # These will only get in the way.
    Item.destroy_all
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

  test 'create_items() with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items() should work' do
    # Set up the fixture data.
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Run the ingest.
    result = @instance.create_items(collection)

    # Assert that the correct number of items were added.
    assert_equal 4, Item.count
    assert_equal 4, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('7b7e08f0-0b13-0134-1d55-0050569601ca-a')
    assert_empty item.items
    assert_equal 2, item.binaries.length
    bs = item.binaries.
        select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal 575834922, bs.byte_size
    assert_equal '/55/2358/preservation/03501042_001_souscrivez.TIF',
                 bs.repository_relative_pathname

    bs = item.binaries.
        select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal 128493361, bs.byte_size
    assert_equal '/55/2358/access/03501042_001_souscrivez.jp2',
                 bs.repository_relative_pathname
  end

  test 'create_items() should extract metadata when told to' do
    # Currently no collections with this profile contain embedded metadata (or
    # at least any that is used).
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
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.create_items(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'].select{ |d| d['name'] == 'preservation' }[0]['files'] =
        tree['subdirectories'].select{ |d| d['name'] == 'preservation' }[0]['files'][0..2]
    cfs_dir.json_tree = tree

    # Delete missing items.
    result = @instance.delete_missing_items(collection)

    # Assert that they were deleted.
    assert_equal start_num_items - 1, Item.count
    assert_equal 1, result[:num_deleted]
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

  test 'replace_metadata should work' do
    # Currently no single-item profile collections contain embedded
    # metadata (or at least any that is used).
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
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.create_items(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all binaries.
    Binary.destroy_all

    # Update binaries.
    result = @instance.update_binaries(collection)

    # Assert that the binaries were created.
    assert_equal 4, result[:num_updated]
    assert_equal Binary.count, result[:num_updated] * 2
    assert_equal start_num_items, Item.count
    assert_equal Item.count * 2, Binary.count
    Item.all.each { |it| assert_equal 2, it.binaries.count }
  end

end
