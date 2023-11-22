require 'test_helper'

class MedusaMixedMediaIngesterTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @ingester   = MedusaMixedMediaIngester.new
    @collection = collections(:mixed_media)
    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() returns nil with top-level items' do
    item = '1db0b737-83ea-5587-d910-06c22eb6c74c'
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() returns the parent UUID with pages' do
    page            = '718035e2-09bb-ed67-ccdc-05ecdf99d999'
    expected_parent = '1db0b737-83ea-5587-d910-06c22eb6c74c'
    assert_equal expected_parent,
                 MedusaMixedMediaIngester.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() returns nil for non-item content' do
    bogus = 'd7c201cf-876e-7768-bd95-6785666a180e' # access folder
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)
    bogus = '7b292841-d8aa-c4e4-6561-eb8f3cb6d00c' # preservation folder
    assert_nil MedusaMixedMediaIngester.parent_id_from_medusa(bogus)
  end

  # create_items()

  test 'create_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
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

  test 'create_items() with collection package profile set incorrectly raises an
  error' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with no effective collection CFS directory raises an
  error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  ##
  # Object packages that have only one child directory are created as
  # standalone items.
  #
  test 'create_items() works with non-compound items' do
    # Run the ingest.
    result = @ingester.create_items(@collection)

    assert_equal 4, result[:num_created]

    # Inspect an item.
    item = Item.find_by_repository_id('1db0b737-83ea-5587-d910-06c22eb6c74c')
    assert_equal '1001', item.title
    assert_nil item.variant
    assert_equal 0, item.items.length
    assert_equal 2, item.binaries.length
    assert_nil item.variant
    assert_equal '084f6359-3213-35d7-a29b-bfee47b6dd9d',
                 item.representative_medusa_file_id

    # Inspect the item's preservation master binary.
    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 46346, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '742ddfb4-5221-22a2-cfdd-9f56647f4746', bin.medusa_uuid
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1001/001/preservation/images/1001_001.tif',
                 bin.object_key

    # Inspect the item's access master binary.
    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '084f6359-3213-35d7-a29b-bfee47b6dd9d', bin.medusa_uuid
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1001/001/access/images/1001_001.jp2',
                 bin.object_key
  end

  test 'create_items() works with compound items' do
    # Run the ingest.
    result = @ingester.create_items(@collection)

    assert_equal 4, result[:num_created]

    # Inspect the parent item.
    item = Item.find_by_repository_id('f6ebc18a-d88b-ecd7-f25e-82c69b4ce470')
    assert_equal '1002', item.title
    assert_nil item.variant

    assert_equal 2, item.items.length
    assert_equal 0, item.binaries.length

    # Inspect a child item.
    child = item.items.find{ |it| it.repository_id == 'a6ff394a-475b-4ea4-5558-795e9ef0f98e' }
    assert_equal '001', child.title
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 46346, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1002/001/preservation/images/1002_001.tif',
                 bin.object_key

    # Inspect the first child's access master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1002/001/access/images/1002_001.jp2',
                 bin.object_key
  end

  # delete_missing()

  test 'delete_missing_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
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

  test 'delete_missing_items() with no effective collection CFS directory raises
  an error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() works' do
    skip if ENV['CI'] == '1' # this doesn't work in CI, maybe because of the way content is moved
    # Ingest some items.
    @ingester.create_items(@collection)

    # Record initial conditions.
    start_num_items = Item.count

    client          = MedusaS3Client.instance
    src_key_prefix  = 'repositories/1/collections/4/file_groups/4/root/1002'
    dest_key_prefix = 'tmp/1002'
    begin
      # Temporarily move some objects out of the path of the ingester.
      client.move_objects(src_key_prefix, dest_key_prefix)

      # Delete the items.
      # First we need to nillify some cached information from before the move. TODO: this is messy
      @collection.instance_variable_set('@file_group', nil)
      @collection.instance_variable_set('@medusa_directory', nil)
      result = @ingester.delete_missing_items(@collection)

      # Assert that they were deleted.
      assert_equal start_num_items - 3, Item.count
      assert_equal 3, result[:num_deleted]
    ensure
      # Move the objects back into place.
      client.move_objects(dest_key_prefix, src_key_prefix)
    end
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with collection package profile not set raises an
  error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with no effective collection directory raises an
  error' do
    @collection.medusa_directory_uuid = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() works' do
    # TODO: write this
  end

  # recreate_binaries()

  test 'recreate_binaries() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with collection package profile not set raises an
  error' do
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

  test 'recreate_binaries() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() works' do
    # Ingest some items.
    result = @ingester.create_items(@collection)

    assert_equal 4, result[:num_created]

    # Delete all binaries.
    Binary.destroy_all

    # Recreate binaries.
    result = @ingester.recreate_binaries(@collection)

    # Assert that the binaries were created.
    assert_equal 6, result[:num_created]
    assert_equal 6, Binary.count

    # Inspect a parent item.
    item = Item.find_by_repository_id('f6ebc18a-d88b-ecd7-f25e-82c69b4ce470')
    assert_equal 0, item.binaries.count

    # Inspect its first child item.
    child = item.items.find{ |it| it.repository_id == 'a6ff394a-475b-4ea4-5558-795e9ef0f98e' }
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 46346, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1002/001/preservation/images/1002_001.tif',
                 bin.object_key

    # Inspect the first child's access master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/4/file_groups/4/root/1002/001/access/images/1002_001.jp2',
                 bin.object_key
  end

end
