require 'test_helper'

class MedusaIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaIngester.new

    # These will only get in the way.
    Item.destroy_all
  end

  test 'ingest_items with collection file group not set should raise an error' do
    collection = collections(:collection1)
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.ingest_items(
          collection, MedusaIngester::IngestMode::CREATE_ONLY)
    end
  end

  test 'ingest_items with collection package profile not set should raise an error' do
    collection = collections(:collection1)
    collection.package_profile = nil

    assert_raises ArgumentError do
      @instance.ingest_items(
          collection, MedusaIngester::IngestMode::CREATE_ONLY)
    end
  end

  test 'ingest_items with no effective collection CFS directory should raise an error' do
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = nil
    collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @instance.ingest_items(
          collection, MedusaIngester::IngestMode::CREATE_ONLY)
    end
  end

  test 'ingest_items with free-form profile collection and create-only ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..0]
    cfs_dir.json_tree = tree

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_ONLY, warnings)

    # Assert that the correct number of items were added.
    assert_equal 0, warnings.length
    assert_equal 7, Item.count
    assert_equal 7, result[:num_created]

    # Inspect an individual directory item more thoroughly.
    item = Item.find_by_repository_id('231fa570-e949-0133-1d3d-0050569601ca-2')
    assert_equal 1, item.items.length
    assert_equal 0, item.bytestreams.length
    assert_equal Item::Variants::DIRECTORY, item.variant

    # Inspect an individual file item more thoroughly.
    item = Item.find_by_repository_id('236763b0-e949-0133-1d3d-0050569601ca-2')
    item.bytestreams.each do |bs|
      assert_equal Bytestream::Type::ACCESS_MASTER, bs.bytestream_type
    end
    assert_empty item.items
    assert_equal 1, item.bytestreams.length
    assert_equal Item::Variants::FILE, item.variant
    assert_equal 'afm0002389.jp2', item.title
    bs = item.bytestreams.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal '/59/2257/afm0002389/access/afm0002389.jp2',
                 bs.repository_relative_pathname
  end

  test 'ingest_items with free-form profile collection and delete-missing ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..1]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.ingest_items(collection, MedusaIngester::IngestMode::CREATE_ONLY)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'] = tree['subdirectories'][0..0]
    cfs_dir.json_tree = tree

    # "Ingest" the items.
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::DELETE_MISSING)

    # Assert that they were deleted.
    assert_equal start_num_items - 7, Item.count
    assert_equal 7, result[:num_deleted]
  end

  test 'ingest_items with free-form profile collection and update-bytestreams ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection1)
    collection.medusa_cfs_directory_id = 'ac1a9850-0b09-0134-1d54-0050569601ca-a'
    cfs_dir = collection.effective_medusa_cfs_directory
    # Not a typo; we're treating this as a free-form tree.
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.ingest_items(collection, MedusaIngester::IngestMode::CREATE_ONLY)

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all their bytestreams.
    Bytestream.destroy_all

    # "Ingest" the items again.
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::UPDATE_BYTESTREAMS)

    # Assert that the bytestreams were created.
    assert_equal Bytestream.count, result[:num_updated]
    Bytestream.all.each do |bs|
      assert_equal Bytestream::Type::ACCESS_MASTER, bs.bytestream_type
    end
    assert_equal start_num_items, Item.count
    assert_equal Item.where(variant: Item::Variants::FILE).count, Bytestream.count
    Item.where(variant: Item::Variants::FILE).each do |it|
      assert_equal 1, it.bytestreams.count
    end
    Item.where(variant: Item::Variants::DIRECTORY).each do |it|
      assert_empty it.bytestreams
    end
  end

  test 'ingest_items with map profile collection, non-compound items, and create-only ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree containing only four items.
    tree['subdirectories'] = tree['subdirectories'][0..3]
    cfs_dir.json_tree = tree

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_ONLY, warnings)

    # Assert that the correct number of items were added.
    assert_equal 0, warnings.length
    assert_equal 4, Item.count
    assert_equal 4, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('2066c390-e946-0133-1d3d-0050569601ca-d')
    assert_nil item.variant
    assert_empty item.items
    assert_equal 2, item.bytestreams.length
    bs = item.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal '/59/2257/afm0002389/preservation/afm0002389.tif',
                 bs.repository_relative_pathname

    bs = item.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal '/59/2257/afm0002389/access/afm0002389.jp2',
                 bs.repository_relative_pathname
  end

  test 'ingest_items with map profile collection, compound items, and create-only ingest mode' do
    # Set up the fixture data.
    item_uuid = '3aa7dd70-e946-0133-1d3d-0050569601ca-d'
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree
    assert_equal 1, cfs_dir.directories.length

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_ONLY, warnings)

    assert_equal 0, warnings.length
    assert_equal 5, result[:num_created]

    # Inspect the item.
    item = Item.find_by_repository_id(item_uuid)
    assert_nil item.variant
    assert_equal 4, item.items.length
    assert_equal 0, item.bytestreams.length

    # Inspect the first child item.
    child = item.items.
        select{ |it| it.repository_id == '458f3300-e949-0133-1d3d-0050569601ca-7' }.first
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 2, child.bytestreams.length

    bs = child.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal '/59/2257/afm0003060/preservation/afm0003060a.tif',
                 bs.repository_relative_pathname

    bs = child.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal '/59/2257/afm0003060/access/afm0003060a.jp2',
                 bs.repository_relative_pathname
  end

  test 'ingest_items with map profile collection and delete-missing ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..9]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.ingest_items(collection, MedusaIngester::IngestMode::CREATE_ONLY)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'] = tree['subdirectories'][0..7]
    cfs_dir.json_tree = tree

    # "Ingest" the items.
    result = @instance.ingest_items(collection,
                                    MedusaIngester::IngestMode::DELETE_MISSING)

    # Assert that they were deleted.
    assert_equal start_num_items - 2, Item.count
    assert_equal 2, result[:num_deleted]
  end

  test 'ingest_items with map profile collection and update-bytestreams ingest mode' do
    # Set up the fixture data.
    item_uuid = '3aa7dd70-e946-0133-1d3d-0050569601ca-d'
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree

    # Ingest some items.
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_ONLY)
    assert_equal 5, result[:num_created]

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all bytestreams.
    Bytestream.destroy_all

    # "Ingest" the items again.
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::UPDATE_BYTESTREAMS)

    # Assert that the bytestreams were created.
    assert_equal 4, result[:num_updated]
    assert_equal Bytestream.count, result[:num_updated] * 2
    assert_equal start_num_items, Item.count
    assert_equal Item.count * 2 - 2, Bytestream.count
    Item.where(variant: Item::Variants::PAGE).each do |it|
      assert_equal 2, it.bytestreams.count
    end
    Item.where('variant != ?', Item::Variants::PAGE).each do |it|
      assert_equal 2, it.bytestreams.count
    end
  end

  test 'ingest_items with single-item object profile collection and create-only ingest mode' do
    # Set up the fixture data.
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(collection,
                                    MedusaIngester::IngestMode::CREATE_ONLY,
                                    warnings)

    # Assert that the correct number of items were added.
    assert_equal 0, warnings.length
    assert_equal 4, Item.count
    assert_equal 4, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('7b7e08f0-0b13-0134-1d55-0050569601ca-a')
    assert_empty item.items
    assert_equal 2, item.bytestreams.length
    bs = item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal '/55/2358/preservation/03501042_001_souscrivez.TIF',
                 bs.repository_relative_pathname

    bs = item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal 'image/jp2', bs.media_type
    assert_equal '/55/2358/access/03501042_001_souscrivez.jp2',
                 bs.repository_relative_pathname
  end

  test 'ingest_items with single-item object profile collection and delete-missing ingest mode' do
    # Set up the fixture data.
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Ingest some items.
    @instance.ingest_items(collection, MedusaIngester::IngestMode::CREATE_ONLY)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'].select{ |d| d['name'] == 'preservation' }[0]['files'] =
        tree['subdirectories'].select{ |d| d['name'] == 'preservation' }[0]['files'][0..2]
    cfs_dir.json_tree = tree

    # "Ingest" the items.
    result = @instance.ingest_items(collection,
                                    MedusaIngester::IngestMode::DELETE_MISSING)

    # Assert that they were deleted.
    assert_equal start_num_items - 1, Item.count
    assert_equal 1, result[:num_deleted]
  end

  test 'ingest_items with single-item object profile collection and update-bytestreams ingest mode' do
    # Set up the fixture data.
    collection = collections(:single_item_object_collection)
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_single_item_tree.json'))
    cfs_dir.json_tree = tree

    # Run the ingest.
    @instance.ingest_items(collection,
                           MedusaIngester::IngestMode::CREATE_ONLY)

    # Record initial conditions.
    start_num_items = Item.count

    # Delete all bytestreams.
    Bytestream.destroy_all

    # "Ingest" the items again.
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::UPDATE_BYTESTREAMS)

    # Assert that the bytestreams were created.
    assert_equal 4, result[:num_updated]
    assert_equal Bytestream.count, result[:num_updated] * 2
    assert_equal start_num_items, Item.count
    assert_equal Item.count * 2, Bytestream.count
    Item.all.each { |it| assert_equal 2, it.bytestreams.count }
  end

end
