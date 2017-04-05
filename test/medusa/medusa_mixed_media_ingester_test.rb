require 'test_helper'

class MedusaMixedMediaIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaMixedMediaIngester.new

    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() should return nil with top-level items' do
    # https://medusa.library.illinois.edu/cfs_directories/1273904.json
    item = 'bc5d68c0-ea4e-0134-23c2-0050569601ca-2'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() should return the parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_directories/1274132.json
    page = 'cdd5cdc0-ea4e-0134-23c2-0050569601ca-8'
    # https://medusa.library.illinois.edu/cfs_directories/1273904.json
    expected_parent = 'bc5d68c0-ea4e-0134-23c2-0050569601ca-2'
    assert_equal expected_parent,
                 MedusaMixedMediaIngester.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() should return nil for non-item content' do
    # access folder
    # https://medusa.library.illinois.edu/cfs_directories/1275947.json
    bogus = '8df7b5e0-ea51-0134-23c2-0050569601ca-0'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)

    # preservation folder
    # https://medusa.library.illinois.edu/cfs_directories/1275948.json
    bogus = '948a3a80-ea51-0134-23c2-0050569601ca-5'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)
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

  test 'create_items() with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.create_items(collection)
    end
  end

  test 'create_items() should work with compound items' do
    # Set up the fixture data.
    item_uuid = 'bb60d790-ea4e-0134-23c2-0050569601ca-d'
    collection = collections(:mixed_media_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    cfs_dir.json_tree =
        JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_mixed_media_tree.json'))
    assert_equal 2, cfs_dir.directories.length

    # Run the ingest.
    result = @instance.create_items(collection)

    assert_equal 10, result[:num_created]

    # Inspect a parent item.
    item = Item.find_by_repository_id(item_uuid)
    assert_equal '1676', item.title
    assert_nil item.variant
    assert_equal 6, item.items.length
    assert_equal 0, item.binaries.length

    # Inspect its first child item.
    child = item.items.
        select{ |it| it.repository_id == '51f81d20-ea50-0134-23c2-0050569601ca-0' }.first
    assert_equal '001', child.title
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 2, child.binaries.length
    assert_equal 'e6c511a0-ea6a-0134-23c2-0050569601ca-2',
                 child.representative_binary.cfs_file_uuid

    # Inspect its first child item's binaries.
    bs = child.binaries.
        select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal 60623897, bs.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bs.media_category
    assert_equal 'e717ad00-ea6a-0134-23c2-0050569601ca-f', bs.cfs_file_uuid
    assert_equal '/1108/2833/1676/001/preservation/images/120993_008_001.tif',
                 bs.repository_relative_pathname

    bs = child.binaries.
        select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal 3419163, bs.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bs.media_category
    assert_equal 'e6c511a0-ea6a-0134-23c2-0050569601ca-2', bs.cfs_file_uuid
    assert_equal '/1108/2833/1676/001/access/images/120993_008_001.jp2',
                 bs.repository_relative_pathname

    # Inspect its 5th child item's binaries.
    child = item.items.
        select{ |it| it.repository_id == '5231e8a0-ea50-0134-23c2-0050569601ca-e' }.first
    assert_equal 10, child.binaries.count
  end

  test 'create_items() should extract metadata when told to' do
    # Currently no mixed media profile collections contain embedded metadata
    # (or at least any that is used).
  end

  # delete_missing()

  test 'delete_missing_items() with collection file group not set should raise an error' do
    collection = collections(:mixed_media_collection)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() with collection package profile not set should raise an error' do
    collection = collections(:mixed_media_collection)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() with collection package profile set incorrectly
  should raise an error' do
    collection = collections(:mixed_media_collection)
    collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() with no effective collection CFS directory should raise an error' do
    collection = collections(:mixed_media_collection)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.delete_missing_items(collection)
    end
  end

  test 'delete_missing_items() should work' do
    # Set up the fixture data.
    collection = collections(:mixed_media_collection)
    collection.medusa_cfs_directory_id = 'bc0b9fb0-ea4e-0134-23c2-0050569601ca-b'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_mixed_media_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..1]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.create_items(collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'][0]['subdirectories'] =
        tree['subdirectories'][0]['subdirectories'][0..3]
    cfs_dir.json_tree = tree

    # Delete the items.
    result = @instance.delete_missing_items(collection)

    # Assert that they were deleted.
    assert_equal start_num_items - 2, Item.count
    assert_equal 2, result[:num_deleted]
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set should raise an
  error' do
    collection = collections(:mixed_media_collection)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() with collection package profile not set should raise
  an error' do
    collection = collections(:mixed_media_collection)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() with no effective collection CFS directory should
  raise an error' do
    collection = collections(:mixed_media_collection)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.replace_metadata(collection)
    end
  end

  test 'replace_metadata() should work' do
    # Currently no mixed media profile collections contain embedded metadata
    # (or at least any that is used).
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
    item_uuid = 'bb60d790-ea4e-0134-23c2-0050569601ca-d'
    collection = collections(:mixed_media_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    cfs_dir.json_tree =
        JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_mixed_media_tree.json'))

    # Ingest some items.
    result = @instance.create_items(collection)
    assert_equal 10, result[:num_created]

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all binaries.
    Binary.destroy_all

    # Update binaries.
    result = @instance.update_binaries(collection)

    # Assert that the binaries were created.
    assert_equal 24, result[:num_created]
    assert_equal start_num_items, Item.count

    # Inspect a parent item.
    item = Item.find_by_repository_id(item_uuid)
    assert_equal 0, item.binaries.length

    # Inspect its first child item.
    child = item.items.
        select{ |it| it.repository_id == '51f81d20-ea50-0134-23c2-0050569601ca-0' }.first
    assert_equal 2, child.binaries.length
    assert_equal 'e6c511a0-ea6a-0134-23c2-0050569601ca-2',
                 child.representative_binary.cfs_file_uuid

    # Inspect its first child item's binaries.
    bs = child.binaries.
        select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal 60623897, bs.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bs.media_category
    assert_equal 'e717ad00-ea6a-0134-23c2-0050569601ca-f', bs.cfs_file_uuid
    assert_equal '/1108/2833/1676/001/preservation/images/120993_008_001.tif',
                 bs.repository_relative_pathname

    bs = child.binaries.
        select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal 3419163, bs.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bs.media_category
    assert_equal 'e6c511a0-ea6a-0134-23c2-0050569601ca-2', bs.cfs_file_uuid
    assert_equal '/1108/2833/1676/001/access/images/120993_008_001.jp2',
                 bs.repository_relative_pathname

    # Inspect its 5th child item's binaries.
    child = item.items.
        select{ |it| it.repository_id == '5231e8a0-ea50-0134-23c2-0050569601ca-e' }.first
    assert_equal 10, child.binaries.count
  end

end
