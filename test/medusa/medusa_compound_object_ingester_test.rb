require 'test_helper'

class MedusaCompoundObjectIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaCompoundObjectIngester.new

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

  test 'create_items() should work with non-compound items' do
    # Set up the fixture data.
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree containing only four items.
    tree['subdirectories'] = tree['subdirectories'][0..3]
    cfs_dir.json_tree = tree

    # Run the ingest.
    result = @instance.create_items(collection)

    # Assert that the correct number of items were added.
    assert_equal 4, Item.count
    assert_equal 4, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('2066c390-e946-0133-1d3d-0050569601ca-d')
    assert_equal 'afm0002389', item.title
    assert_nil item.variant
    assert_empty item.items
    assert_equal 2, item.binaries.length

    bs = item.binaries.select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal 28184152, bs.byte_size
    assert_equal '/59/2257/afm0002389/preservation/afm0002389.tif',
                 bs.repository_relative_pathname

    bs = item.binaries.select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal 9665238, bs.byte_size
    assert_equal '/59/2257/afm0002389/access/afm0002389.jp2',
                 bs.repository_relative_pathname
  end

  test 'create_items() should work with compound items' do
    # Set up the fixture data.
    item_uuid = '3aa7dd70-e946-0133-1d3d-0050569601ca-d'
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree
    assert_equal 1, cfs_dir.directories.length

    # Run the ingest.
    result = @instance.create_items(collection)

    assert_equal 5, result[:num_created]

    # Inspect the parent item.
    item = Item.find_by_repository_id(item_uuid)
    assert_equal 'afm0003060', item.title
    assert_nil item.variant
    assert_equal 4, item.items.length
    assert_equal 0, item.binaries.length

    # Inspect the first child item.
    child = item.items.
        select{ |it| it.repository_id == '458f3300-e949-0133-1d3d-0050569601ca-7' }.first
    assert_equal 'afm0003060a.tif', child.title
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 2, child.binaries.length

    bs = child.binaries.select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal 43204936, bs.byte_size
    assert_equal '/59/2257/afm0003060/preservation/afm0003060a.tif',
                 bs.repository_relative_pathname

    bs = child.binaries.select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal 15095518, bs.byte_size
    assert_equal '/59/2257/afm0003060/access/afm0003060a.jp2',
                 bs.repository_relative_pathname
  end

  test 'create_items() should extract metadata when told to' do
    # Currently no compound object profile collections contain embedded
    # metadata (or at least any that is used).
  end

  # delete_missing()

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

  test 'delete_missing_items() with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() should work' do
    # Set up the fixture data.
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..9]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.create_items(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'] = tree['subdirectories'][0..7]
    cfs_dir.json_tree = tree

    # Delete the items.
    result = @instance.delete_missing_items(collection)

    # Assert that they were deleted.
    assert_equal start_num_items - 2, Item.count
    assert_equal 2, result[:num_deleted]
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

  test 'replace_metadata() with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() should work' do
    # Currently no compound object profile collections contain embedded
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

  test 'update_binaries() with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.update_binaries(collection)
    end
  end

  test 'update_binaries() should work' do
    # Set up the fixture data.
    item_uuid = '3aa7dd70-e946-0133-1d3d-0050569601ca-d'
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree

    # Ingest some items.
    result = @instance.create_items(collection)
    assert_equal 5, result[:num_created]

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
    assert_equal Item.count * 2 - 2, Binary.count
    Item.where(variant: Item::Variants::PAGE).each do |it|
      assert_equal 2, it.binaries.count
    end
    Item.where('variant != ?', Item::Variants::PAGE).each do |it|
      assert_equal 2, it.binaries.count
    end
  end

end