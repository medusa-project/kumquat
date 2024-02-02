require 'test_helper'

class MedusaCompoundObjectIngesterTest < ActiveSupport::TestCase

  setup do
    setup_opensearch
    @collection = collections(:compound_object)
    @ingester = MedusaCompoundObjectIngester.new
    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() returns nil with top-level items' do
    item = '21353276-887c-0f2b-25a0-ed444003303f'
    assert_nil MedusaCompoundObjectIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() returns the parent UUID with pages' do
    page            = '8ec70c33-75c9-4ba5-cd21-54a1211e5375'
    expected_parent = '21353276-887c-0f2b-25a0-ed444003303f'
    assert_equal expected_parent,
                 MedusaCompoundObjectIngester.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() returns nil for non-item content' do
    bogus = 'e875de33-97c5-4526-beea-74c3339dcf40'
    assert_nil MedusaCompoundObjectIngester.parent_id_from_medusa(bogus)
  end

  # create_items()

  test 'create_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.create_items(collection: @collection)
    end
  end

  test 'create_items() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.create_items(collection: @collection)
    end
  end

  test 'create_items() with collection package profile set incorrectly raises
  an error' do
    @collection.package_profile = PackageProfile::FREE_FORM_PROFILE
    assert_raises ArgumentError do
      @ingester.create_items(collection: @collection)
    end
  end

  test 'create_items() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.create_items(collection: @collection)
    end
  end

  ##
  # Object packages that have only one access & preservation master file are
  # created as standalone items, i.e. non-compound objects.
  #
  test 'create_items() works with non-compound items' do
    # Run the ingest.
    result = @ingester.create_items(collection: @collection)

    # Assert that the correct number of items were added.
    assert_equal 5, Item.count
    assert_equal 5, result[:num_created]

    # Inspect the relevant item more thoroughly.
    item = Item.find_by_repository_id('21353276-887c-0f2b-25a0-ed444003303f')
    assert_equal '1001', item.title
    assert_nil item.variant
    assert_empty item.items
    assert_equal 2, item.binaries.length

    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 46346, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1001/preservation/1001_001.tif',
                 bin.object_key

    bin = item.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1001/access/1001_001.jp2',
                 bin.object_key
  end

  test 'create_items() works with compound items' do
    # Run the ingest.
    result = @ingester.create_items(collection: @collection)

    assert_equal 5, result[:num_created]

    # Inspect the parent item.
    item = Item.find_by_repository_id('6bc86d3b-e321-1a63-5172-fbf9a6e1aaab')
    assert_equal '1002', item.title
    assert_nil item.variant

    assert_equal 3, item.items.length
    assert_equal 0, item.binaries.length

    # Inspect the first child item.
    child = item.items.find{ |it| it.repository_id == '6a1d73f2-3493-1ca8-80e5-84a49d524f92' }
    assert_equal '1002_001.tif', child.title
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 0, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/preservation/1002_001.tif',
                 bin.object_key

    # Inspect the first child's access master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/access/1002_001.jp2',
                 bin.object_key

    # Inspect the supplementary child item.
    child = item.items.find{ |it| it.variant == Item::Variants::SUPPLEMENT }
    assert_equal 1, child.binaries.count
    bin = child.binaries.first
    assert_equal 'text/plain', bin.media_type
    assert_equal 0, bin.byte_size
    assert_equal Binary::MediaCategory::TEXT, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/supplementary/text.txt',
                 bin.object_key
  end

  # delete_missing_items()

  test 'delete_missing_items() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(collection: @collection)
    end
  end

  test 'delete_missing_items() with collection package profile not set raises an
  error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(collection: @collection)
    end
  end

  test 'delete_missing_items() with collection package profile set incorrectly
  raises an error' do
    @collection.package_profile = PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.delete_missing_items(collection: @collection)
    end
  end

  test 'delete_missing_items() with no effective collection directory raises an
  error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.delete_missing_items(collection: @collection)
    end
  end

  test 'delete_missing_items() works' do
    skip if ENV['CI'] == '1' # this doesn't work in CI, maybe because of the way content is moved
    # Ingest some items.
    @ingester.create_items(collection: @collection)

    # Record initial conditions.
    start_num_items = Item.count

    client          = MedusaS3Client.instance
    src_key_prefix  = 'repositories/1/collections/3/file_groups/3/root/1002'
    dest_key_prefix = 'tmp/1002'
    begin
      # Temporarily move some objects out of the path of the ingester.
      client.move_objects(src_key_prefix, dest_key_prefix)

      # Delete the items.
      # First we need to nillify some cached information from before the move. TODO: this is messy
      @collection.instance_variable_set('@file_group', nil)
      @collection.instance_variable_set('@medusa_directory', nil)
      result = @ingester.delete_missing_items(collection: @collection)

      # Assert that they were deleted.
      assert_equal start_num_items - 4, Item.count
      assert_equal 4, result[:num_deleted]
    ensure
      # Move the objects back into place.
      client.move_objects(dest_key_prefix, src_key_prefix)
    end
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(collection: @collection)
    end
  end

  test 'replace_metadata() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(collection: @collection)
    end
  end

  test 'replace_metadata() with no effective collection CFS directory raises an
  error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(collection: @collection)
    end
  end

  test 'replace_metadata() works' do
    # TODO: write this
  end

  # recreate_binaries()

  test 'recreate_binaries() with collection file group not set raises an error' do
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(collection: @collection)
    end
  end

  test 'recreate_binaries() with collection package profile not set raises an
  error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(collection: @collection)
    end
  end

  test 'recreate_binaries() with collection package profile set incorrectly
  raises an error' do
    @collection.package_profile = PackageProfile::FREE_FORM_PROFILE
    assert_raises ArgumentError do
      @ingester.recreate_binaries(collection: @collection)
    end
  end

  test 'recreate_binaries() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(collection: @collection)
    end
  end

  test 'recreate_binaries() works' do
    # Ingest some items.
    result = @ingester.create_items(collection: @collection)

    assert_equal 5, result[:num_created]

    # Delete all binaries.
    Binary.destroy_all

    # Recreate binaries.
    result = @ingester.recreate_binaries(collection: @collection)

    # Assert that the binaries were created.
    assert_equal 7, result[:num_created]
    assert_equal 7, Binary.count

    # Inspect a single-item object.
    item = Item.find_by_repository_id('21353276-887c-0f2b-25a0-ed444003303f')
    assert_equal 2, item.binaries.count

    # Inspect a compound object parent item.
    item = Item.find_by_repository_id('6bc86d3b-e321-1a63-5172-fbf9a6e1aaab')
    assert_equal 0, item.binaries.count

    # Inspect the first child item.
    child = item.items.find{ |it| it.repository_id == '6a1d73f2-3493-1ca8-80e5-84a49d524f92' }
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
    assert_equal 'image/tiff', bin.media_type
    assert_equal 0, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/preservation/1002_001.tif',
                 bin.object_key

    # Inspect the first child's access master.
    bin = child.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    assert_equal 'image/jp2', bin.media_type
    assert_equal 18836, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/access/1002_001.jp2',
                 bin.object_key

    # Inspect the supplementary item.
    child = item.items.find{ |it| it.variant == Item::Variants::SUPPLEMENT }
    assert_equal 1, child.binaries.count
    bin = child.binaries.first
    assert_equal 'text/plain', bin.media_type
    assert_equal 0, bin.byte_size
    assert_equal Binary::MediaCategory::TEXT, bin.media_category
    assert_equal 'repositories/1/collections/3/file_groups/3/root/1002/supplementary/text.txt',
                 bin.object_key
  end

end
