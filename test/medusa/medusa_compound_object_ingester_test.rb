require 'test_helper'

class MedusaCompoundObjectIngesterTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:sanborn)
    @ingester = MedusaCompoundObjectIngester.new

    # These will only get in the way.
    Item.destroy_all
  end

  # parent_id_from_medusa()

  test 'parent_id_from_medusa() should return nil with top-level items' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    item = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_nil MedusaCompoundObjectIngester.parent_id_from_medusa(item)
  end

  test 'parent_id_from_medusa() should return the parent UUID with pages' do
    # https://medusa.library.illinois.edu/cfs_files/9799301.json
    page = 'd853fad0-c451-0133-1d17-0050569601ca-7'
    # https://medusa.library.illinois.edu/cfs_directories/413276.json
    expected_parent = 'ae3991e0-c451-0133-1d17-0050569601ca-b'
    assert_equal expected_parent,
                 MedusaCompoundObjectIngester.parent_id_from_medusa(page)
  end

  test 'parent_id_from_medusa() should return nil for non-item content' do
    # https://medusa.library.illinois.edu/cfs_directories/414759.json
    bogus = 'd83e6f60-c451-0133-1d17-0050569601ca-8'
    assert_nil MedusaCompoundObjectIngester.parent_id_from_medusa(bogus)
  end

  # create_items()

  test 'create_items() with collection file group not set should raise an error' do
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with collection package profile not set should raise an
  error' do
    @collection.package_profile = nil

    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with collection package profile set incorrectly should
  raise an error' do
    @collection.package_profile = PackageProfile::FREE_FORM_PROFILE

    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  test 'create_items() with no effective collection CFS directory should raise
  an error' do
    @collection.medusa_cfs_directory_id = nil
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.create_items(@collection)
    end
  end

  ##
  # Object packages that have only one access & preservation master file are
  # created as standalone items, i.e. non-compound objects.
  #
  test 'create_items() should work with non-compound items' do
    # Set up the fixture data.
    @collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = @collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree containing only four items.
    tree['subdirectories'] = tree['subdirectories'][0..3]
    cfs_dir.json_tree = tree

    # Run the ingest.
    result = @ingester.create_items(@collection)

    # Assert that the correct number of items were added.
    assert_equal 4, Item.count
    assert_equal 4, result[:num_created]

    # Inspect an individual item more thoroughly.
    item = Item.find_by_repository_id('2066c390-e946-0133-1d3d-0050569601ca-d')
    assert_equal 'afm0002389', item.title
    assert_nil item.variant
    assert_empty item.items
    assert_equal 2, item.binaries.length

    bin = item.binaries.select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first
    assert_equal 'image/tiff', bin.media_type
    assert_equal 28184152, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/59/2257/afm0002389/preservation/afm0002389.tif',
                 bin.repository_relative_pathname

    bin = item.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal 'image/jp2', bin.media_type
    assert_equal 9665238, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/59/2257/afm0002389/access/afm0002389.jp2',
                 bin.repository_relative_pathname
  end

  test 'create_items() should work with compound items' do
    # Set up the fixture data.
    item_uuid = '441c6170-c0e6-0134-2373-0050569601ca-5'
    cfs_dir = @collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_myers_collection_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree
    assert_equal 1, cfs_dir.directories.length

    # Run the ingest.
    result = @ingester.create_items(@collection)

    assert_equal 10, result[:num_created]

    # Inspect the parent item.
    item = Item.find_by_repository_id(item_uuid)
    assert_equal '1477', item.title
    assert_nil item.variant

    assert_equal 9, item.items.length
    assert_equal 0, item.binaries.length

    # Inspect the first child item.
    child = item.items.
        select{ |it| it.repository_id == 'c12cd550-c559-0134-2373-0050569601ca-d' }.first
    assert_equal '2014_12996_227_001.tif', child.title
    assert_equal Item::Variants::PAGE, child.variant
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first
    assert_equal 'image/tiff', bin.media_type
    assert_equal 305057420, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/1164/2754/1477/preservation/2014_12996_227_001.tif',
                 bin.repository_relative_pathname

    # Inspect the first child's access master.
    bin = child.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal 'image/jp2', bin.media_type
    assert_equal 215051029, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/1164/2754/1477/access/2014_12996_227_001.jp2',
                 bin.repository_relative_pathname

    # Inspect the supplementary child item.
    child = item.items.select{ |it| it.variant == Item::Variants::SUPPLEMENT }.first
    assert_equal 1, child.binaries.count
    bin = child.binaries.first
    assert_equal 'application/pdf', bin.media_type
    assert_equal 95195, bin.byte_size
    assert_equal Binary::MediaCategory::DOCUMENT, bin.media_category
    assert_equal '/1164/2754/1477/supplementary/1531.pdf',
                 bin.repository_relative_pathname

    # TODO: inspect composite child item (not available in this collection)
  end

  test 'create_items() should extract metadata when told to' do
    # TODO: write this
  end

  test 'create_items() should not modify existing items' do
    # TODO: write this
  end

  # delete_missing()

  test 'delete_missing_items() with collection file group not set should raise
  an error' do
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with collection package profile not set should
  raise an error' do
    @collection.package_profile = nil

    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with collection package profile set incorrectly
  should raise an error' do
    @collection.package_profile = PackageProfile::SINGLE_ITEM_OBJECT_PROFILE

    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() with no effective collection CFS directory
  should raise an error' do
    @collection.medusa_cfs_directory_id = nil
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.delete_missing_items(@collection)
    end
  end

  test 'delete_missing_items() should work' do
    # Set up the fixture data.
    @collection.medusa_cfs_directory_id = '19c62760-e894-0133-1d3c-0050569601ca-d'
    cfs_dir = @collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_compound_object_tree.json'))
    # Extract a small slice of the tree.
    tree['subdirectories'] = tree['subdirectories'][0..9]
    cfs_dir.json_tree = tree

    # Ingest some items.
    @ingester.create_items(@collection)

    # Record initial conditions.
    start_num_items = Item.count

    # Slice off some items from the ingest data.
    tree['subdirectories'] = tree['subdirectories'][0..7]
    cfs_dir.json_tree = tree

    # Delete the items.
    result = @ingester.delete_missing_items(@collection)

    # Assert that they were deleted.
    assert_equal start_num_items - 2, Item.count
    assert_equal 2, result[:num_deleted]
  end

  # replace_metadata()

  test 'replace_metadata() with collection file group not set should raise an
  error' do
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with collection package profile not set should raise
  an error' do
    @collection.package_profile = nil

    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() with no effective collection CFS directory should
  raise an error' do
    @collection.medusa_cfs_directory_id = nil
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.replace_metadata(@collection)
    end
  end

  test 'replace_metadata() should work' do
    # Currently no compound object profile collections contain embedded
    # metadata (or at least any that is used).
  end

  # recreate_binaries()

  test 'recreate_binaries() with collection file group not set should raise an
  error' do
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with collection package profile not set should
  raise an error' do
    @collection.package_profile = nil

    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with collection package profile set incorrectly
  should raise an error' do
    @collection.package_profile = PackageProfile::FREE_FORM_PROFILE

    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() with no effective collection CFS directory should
  raise an error' do
    @collection.medusa_cfs_directory_id = nil
    @collection.medusa_file_group_id = nil

    assert_raises ArgumentError do
      @ingester.recreate_binaries(@collection)
    end
  end

  test 'recreate_binaries() should work' do
    # Set up the fixture data.
    item_uuid = '441c6170-c0e6-0134-2373-0050569601ca-5'
    cfs_dir = @collection.effective_medusa_cfs_directory
    tree = JSON.parse(File.read(__dir__ + '/../fixtures/repository/medusa_myers_collection_tree.json'))
    # Extract a small slice of the tree containing only one top-level item.
    tree['subdirectories'] = tree['subdirectories'].
        select{ |d| d['uuid'] == item_uuid }
    cfs_dir.json_tree = tree

    # Ingest some items.
    result = @ingester.create_items(@collection)

    assert_equal 10, result[:num_created]

    # Delete all binaries.
    Binary.destroy_all

    # Recreate binaries.
    result = @ingester.recreate_binaries(@collection)

    # Assert that the binaries were created.
    assert_equal 17, result[:num_created]
    assert_equal 17, Binary.count

    # Inspect the parent item.
    item = Item.where(parent_repository_id: nil).first
    assert_equal 0, item.binaries.count

    # Inspect the first child item.
    child = item.items.
        select{ |it| it.repository_id == 'c12cd550-c559-0134-2373-0050569601ca-d' }.first
    assert_equal 2, child.binaries.length

    # Inspect the first child's preservation master.
    bin = child.binaries.select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first
    assert_equal 'image/tiff', bin.media_type
    assert_equal 305057420, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/1164/2754/1477/preservation/2014_12996_227_001.tif',
                 bin.repository_relative_pathname

    # Inspect the first child's access master.
    bin = child.binaries.select{ |b| b.master_type == Binary::MasterType::ACCESS }.first
    assert_equal 'image/jp2', bin.media_type
    assert_equal 215051029, bin.byte_size
    assert_equal Binary::MediaCategory::IMAGE, bin.media_category
    assert_equal '/1164/2754/1477/access/2014_12996_227_001.jp2',
                 bin.repository_relative_pathname

    # Inspect the supplementary item.
    child = item.items.select{ |it| it.variant == Item::Variants::SUPPLEMENT }.first
    assert_equal 1, child.binaries.count
    bin = child.binaries.first
    assert_equal 'application/pdf', bin.media_type
    assert_equal 95195, bin.byte_size
    assert_equal Binary::MediaCategory::DOCUMENT, bin.media_category
    assert_equal '/1164/2754/1477/supplementary/1531.pdf',
                 bin.repository_relative_pathname

    # TODO: test composite content (not available in this collection)
  end

end
