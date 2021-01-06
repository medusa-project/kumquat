require 'test_helper'

class MedusaFreeFormIngesterTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @collection = collections(:free_form)
    @ingester = MedusaFreeFormIngester.new
    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() returns nil with top-level items' do
    item = '7351760f-4b7b-5a6c-6dda-f5a92562b008'
    assert_nil MedusaFreeFormIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() returns the parent UUID with non-top-level items' do
    page            = '088a49f2-08f0-f43b-47a1-cd40cbc1d837'
    expected_parent = '7351760f-4b7b-5a6c-6dda-f5a92562b008'
    assert_equal expected_parent,
                 MedusaFreeFormIngester.parent_id_from_medusa(page)
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

  test 'create_items() with collection package profile set incorrectly
  raises an error' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with no effective collection directory raises an error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() works' do
    skip if ENV['CI'] == '1' # TODO: unskip this after migrating to medusa-client
    # Run the ingest.
    result = @ingester.create_items(@collection)

    # Assert that the correct number of items were added.
    assert_equal 6, Item.count
    assert_equal 6, result[:num_created]
    assert_equal 0, result[:num_skipped]
    assert_equal 6, result[:num_walked]

    # Inspect an individual directory item more thoroughly.
    item = Item.find_by_repository_id('7351760f-4b7b-5a6c-6dda-f5a92562b008')
    assert_equal 0, item.binaries.length
    assert_equal Item::Variants::DIRECTORY, item.variant

    # Inspect an individual file item more thoroughly.
    item = Item.find_by_repository_id('39582239-4307-1cc6-c9c6-074516fd7635')
    item.binaries.each do |bin|
      assert_equal Binary::MasterType::ACCESS, bin.master_type
    end
    assert_empty item.items
    assert_equal 1, item.binaries.length
    assert_equal Item::Variants::FILE, item.variant
    assert_equal 1, item.elements.length
    assert_equal 'image1.jpg', item.title

    bin = item.binaries.first
    assert_equal 6302, bin.byte_size
    assert_equal 'image/jpeg', bin.media_type
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal 'repositories/1/collections/1/file_groups/1/root/dir1/image1.jpg',
                 bin.object_key
  end

  test 'create_items() extracts metadata when told to' do
    skip if ENV['CI'] == '1' # TODO: unskip this after migrating to medusa-client
    # Run the ingest.
    @ingester.create_items(@collection, extract_metadata: true)

    # Assert that the metadata was extracted.
    item = Item.find_by_repository_id('39582239-4307-1cc6-c9c6-074516fd7635') # free_form_dir1_image
    assert item.elements.select{ |e| e.name == 'title' }.map(&:value).
        include?('Escher Lego')
    assert item.elements.select{ |e| e.name == 'creator' }.map(&:value).
        include?('Lego Enthusiast')
  end

  test 'create_items() does not extract metadata when told not to' do
    skip if ENV['CI'] == '1' # TODO: unskip this after migrating to medusa-client
    # Run the ingest.
    @ingester.create_items(@collection, extract_metadata: false)

    # Assert that metadata was not extracted.
    item = Item.find_by_repository_id('39582239-4307-1cc6-c9c6-074516fd7635') # free_form_dir1_image
    assert_equal 'image1.jpg', item.title
    assert item.elements.select{ |e| e.name == 'creator' }.empty?
  end

  # delete_missing_items()

  test 'delete_missing_items() with collection file group not set raises an
  error' do
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
    skip if ENV['CI'] == '1' # TODO: unskip this after migrating to medusa-client
    # Ingest some items.
    @ingester.create_items(@collection)

    # Record initial conditions.
    start_num_items = Item.count

    client          = MedusaS3Client.instance
    src_key_prefix  = 'repositories/1/collections/1/file_groups/1/root/dir1/dir1'
    dest_key_prefix = 'tmp/dir1'
    begin
      # Temporarily move some objects out of the path of the ingester.
      client.move_objects(src_key_prefix, dest_key_prefix)

      # Delete the items.
      # First we need to nillify some cached information from before the move. TODO: this is messy
      @collection.instance_variable_set('@file_group', nil)
      @collection.instance_variable_set('@medusa_directory', nil)
      result = @ingester.delete_missing_items(@collection)

      # Assert that they were deleted.
      assert_equal start_num_items - 2, Item.count
      assert_equal 2, result[:num_deleted]
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

  test 'replace_metadata() with collection package profile not set raises an error' do
    @collection.package_profile = nil
    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with no effective collection CFS directory raises an
  error' do
    @collection.medusa_directory_uuid  = nil
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

  test 'recreate_binaries() with no effective collection CFS directory raises an
  error' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = nil
    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() works' do
    # Ingest some items.
    @ingester.create_items(@collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all of their binaries.
    Binary.destroy_all

    # Recreate binaries.
    result = @ingester.recreate_binaries(@collection)

    # Assert that the binaries were created.
    assert_equal Binary.count, result[:num_created]
    Binary.all.each do |bin|
      assert_equal Binary::MasterType::ACCESS, bin.master_type
    end
    assert_equal start_num_items, Item.count
    assert_equal Item.where(variant: Item::Variants::FILE).count, Binary.count
    Item.where(variant: Item::Variants::FILE).each do |item|
      assert_equal 1, item.binaries.count
    end
    Item.where(variant: Item::Variants::DIRECTORY).each do |item|
      assert_empty item.binaries
    end
  end

end
