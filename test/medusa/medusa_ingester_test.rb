require 'test_helper'

class MedusaIngesterTest < ActiveSupport::TestCase

  setup do
    @instance = MedusaIngester.new
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

    # These will only get in the way.
    Item.destroy_all

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
    assert_empty item.items
    assert_equal 1, item.bytestreams.length
    assert_equal Item::Variants::FILE, item.variant
    bs = item.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
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

    # These will only get in the way.
    Item.destroy_all

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

  test 'ingest_items with map profile collection, non-compound items, and create-only ingest mode' do
    # Set up the fixture data.
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree containing only four items.
    tree['subdirectories'] = tree['subdirectories'][0..3]
    cfs_dir.json_tree = tree

    # These will only get in the way.
    Item.destroy_all

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

  test 'ingest_items with map profile collection, compound items, and create-and-update ingest mode' do
    # Set up the fixture data.
    item_uuid = '3aa7dd70-e946-0133-1d3d-0050569601ca-d'
    collection = collections(:collection2)
    collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = collection.effective_medusa_cfs_directory

    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    # Slice off the access master folder.
    tree['subdirectories'].select{ |d| d['uuid'] == item_uuid }.first['subdirectories'] =
        tree['subdirectories'].select{ |d| d['uuid'] == item_uuid }.first['subdirectories'].reject{ |d| d['name'] == 'access' }
    cfs_dir.json_tree = tree
    assert_equal 1, cfs_dir.directories.length

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_ONLY, warnings)

    assert_equal 4, warnings.length
    assert_equal 5, result[:num_created]

    # Inspect the item.
    item = Item.find_by_repository_id(item_uuid)
    assert_nil item.variant
    assert_equal 4, item.items.length
    assert_equal 0, item.bytestreams.length

    # Inspect the first child item. It should have only one bytestream.
    child = item.items.
        select{ |it| it.repository_id == '458f3300-e949-0133-1d3d-0050569601ca-7' }.first
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 1, child.bytestreams.length

    bs = child.bytestreams.select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal 'image/tiff', bs.media_type
    assert_equal '/59/2257/afm0003060/preservation/afm0003060a.tif',
                 bs.repository_relative_pathname

    # Now, do it all over again, except don't slice off the access master folder.
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_map_tree.json'))
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree
    assert_equal 1, cfs_dir.directories.length

    # Run the ingest.
    warnings = []
    result = @instance.ingest_items(
        collection, MedusaIngester::IngestMode::CREATE_AND_UPDATE, warnings)

    assert_equal 0, warnings.length
    assert_equal 0, result[:num_created]
    assert_equal 5, result[:num_updated]

    # Inspect the item.
    item = Item.find_by_repository_id(item_uuid)
    assert_nil item.variant
    assert_equal 4, item.items.length
    assert_equal 0, item.bytestreams.length

    # Inspect the first child item. It should now have two bytestreams
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

    # These will only get in the way.
    Item.destroy_all

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

end
