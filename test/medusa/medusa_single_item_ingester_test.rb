require 'test_helper'

class MedusaSingleItemIngesterTest < ActiveSupport::TestCase

  setup do
    @ingester = MedusaSingleItemIngester.new
    @collection = collections(:single_item_object)
    # These will only get in the way.
    Item.destroy_all
  end

  # create_items()

  test 'create_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_id = nil
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with collection package profile set incorrectly raises
  an error' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid = nil
    @collection.medusa_file_group_id  = nil
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() works' do
    # Run the ingest.
    result = @ingester.create_items(@collection)

    # Assert that the correct number of items were added.
    assert_equal 2, Item.count
    assert_equal 2, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('cbbc845c-167a-60df-df6e-41a249a43b7c')
    assert_empty item.items
    assert_equal 2, item.binaries.length
    binary = item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', binary.media_type
    assert_equal Binary::MediaCategory::IMAGE, binary.media_category
    assert_equal 46346, binary.byte_size
    assert_equal 'repositories/1/collections/2/file_groups/2/root/preservation/001.tif',
                 binary.object_key

    binary = item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', binary.media_type
    assert_equal 18836, binary.byte_size
    assert_equal 'repositories/1/collections/2/file_groups/2/root/access/001.jp2',
                 binary.object_key
  end

  test 'create_items() extracts metadata when told to' do
    # Run the ingest.
    @ingester.create_items(@collection, extract_metadata: true)

    # Inspect the first item.
    item = Item.find_by_repository_id('cbbc845c-167a-60df-df6e-41a249a43b7c')
    assert_equal 'Escher Lego', item.title
  end

  test 'create_items() does not extract metadata when told not to' do
    # Run the ingest.
    @ingester.create_items(@collection, extract_metadata: false)

    # Inspect an item.
    item = Item.find_by_repository_id('cbbc845c-167a-60df-df6e-41a249a43b7c')
    assert_equal '001.tif', item.title
  end

  test 'create_items() does not modify existing items' do
    # Ingest the items (without extracting metdaata).
    @ingester.create_items(@collection)

    # Record initial conditions.
    assert_equal 2, Item.count
    item = Item.find_by_repository_id('cbbc845c-167a-60df-df6e-41a249a43b7c')
    assert_equal '001.tif', item.title

    # Ingest again, extracting metadata.
    @ingester.create_items(@collection, extract_metadata: true)
    assert_equal 2, Item.count

    # Assert that the item's title hasn't changed.
    item.reload
    assert_equal '001.tif', item.title
  end

  # delete_missing_items()

  test 'delete_missing_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_id = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with collection package profile not set raises
  an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with collection package profile set incorrectly
  raises an error' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with no effective collection directory raises an
  error' do
    @collection.medusa_directory_uuid = nil
    @collection.medusa_file_group_id  = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() works' do
    skip if ENV['CI'] == '1' # TODO: unskip this after migrating to medusa-client
    # Ingest some items.
    @ingester.create_items(@collection)

    # Record initial conditions.
    start_num_items = Item.count

    client     = MedusaS3Client.instance
    src_key_1  = 'repositories/1/collections/2/file_groups/2/root/access/001.jp2'
    dest_key_1 = 'tmp/001.jp2'
    src_key_2  = 'repositories/1/collections/2/file_groups/2/root/preservation/001.tif'
    dest_key_2 = 'tmp/001.tif'
    begin
      # Temporarily move some objects (comprising an item) out of the path of
      # the ingester.
      client.move_object(src_key_1, dest_key_1)
      client.move_object(src_key_2, dest_key_2)

      # Delete the item.
      # First we need to nillify some cached information from before the move. TODO: this is messy
      @collection.instance_variable_set('@file_group', nil)
      @collection.instance_variable_set('@cfs_directory', nil)
      result = @ingester.delete_missing_items(@collection)

      # Assert that they were deleted.
      assert_equal start_num_items - 1, Item.count
      assert_equal 1, result[:num_deleted]
    ensure
      # Move the objects back into place.
      client.move_object(dest_key_1, src_key_1)
      client.move_object(dest_key_2, src_key_2)
    end
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set raise an error' do
    @collection.medusa_file_group_id = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid = nil
    @collection.medusa_file_group_id  = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() works' do
    # TODO: do this
  end

  # recreate_binaries()

  test 'recreate_binaries() with collection file group not set raises an error' do
    @collection.medusa_file_group_id = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with collection package profile set incorrectly
  raises an error' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with no effective collection CFS directory raises an
  error' do
    @collection.medusa_directory_uuid = nil
    @collection.medusa_file_group_id  = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() works' do
    # Ingest some items.
    result = @ingester.create_items(@collection)

    assert_equal 2, result[:num_created]

    # Delete all binaries.
    Binary.destroy_all

    # Recreate binaries.
    result = @ingester.recreate_binaries(@collection)

    # Assert that the binaries were created.
    assert_equal 4, result[:num_created]
    assert_equal 4, Binary.count

    # Inspect the item.
    item = Item.find_by_repository_id('cbbc845c-167a-60df-df6e-41a249a43b7c')
    assert_equal 2, item.binaries.count

    # Inspect the item's preservation master.
    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 46346, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/2/file_groups/2/root/preservation/001.tif',
                 bin.object_key

    # Inspect the item's access master.
    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/2/file_groups/2/root/access/001.jp2',
                 bin.object_key
  end

end
