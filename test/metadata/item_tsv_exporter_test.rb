require 'test_helper'

class ItemTsvExporterTest < ActiveSupport::TestCase

  setup do
    @instance = ItemTsvExporter.new
  end

  # items_in_collection()

  test 'items_in_collection works' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        latitude longitude contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)
    expected_values = [
        {
            'uuid': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': 'sanborn',
            'contentdmPointer': 150,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'd29950d0-c451-0133-1d17-0050569601ca-2',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': '/162/2204/1601831/preservation/1601831_001.tif',
            'preservationMasterFilename': '1601831_001.tif',
            'preservationMasterUUID': 'd29950d0-c451-0133-1d17-0050569601ca-2',
            'accessMasterPathname': '/162/2204/1601831/access/1601831_001.jp2',
            'accessMasterFilename': '1601831_001.jp2',
            'accessMasterUUID': 'd25db810-c451-0133-1d17-0050569601ca-3',
            'variant': 'Page',
            'pageNumber': '1',
            'subpageNumber': nil,
            'latitude': '45.0000000',
            'longitude': '-120.0000000',
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '2',
            'Title': 'My Great Title',
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': 'My Great Description',
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': '/162/2204/1601831/preservation/1601831_002.tif',
            'preservationMasterFilename': '1601831_002.tif',
            'preservationMasterUUID': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'accessMasterPathname': '/162/2204/1601831/access/1601831_002.jp2',
            'accessMasterFilename': '1601831_002.jp2',
            'accessMasterUUID': 'd2650710-c451-0133-1d17-0050569601ca-1',
            'variant': 'Page',
            'pageNumber': '2',
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'cd2d4601-c451-0133-1d17-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        }
    ]
    collection = collections(:sanborn)
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection)
  end

  test 'items_in_collection works with the only_undescribed: true option' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        latitude longitude contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)

    # There should not be any IGNORE column values > 0.
    expected_values = [
        {
            'uuid': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': 'sanborn',
            'contentdmPointer': 150,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': '/162/2204/1601831/preservation/1601831_002.tif',
            'preservationMasterFilename': '1601831_002.tif',
            'preservationMasterUUID': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'accessMasterPathname': '/162/2204/1601831/access/1601831_002.jp2',
            'accessMasterFilename': '1601831_002.jp2',
            'accessMasterUUID': 'd2650710-c451-0133-1d17-0050569601ca-1',
            'variant': 'Page',
            'pageNumber': '2',
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'cd2d4601-c451-0133-1d17-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        }
    ]
    collection = collections(:sanborn)
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection, only_undescribed: true)
  end

  # items_in_item_set()

  test 'items_in_item_set works' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        latitude longitude contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)
    expected_values = [
        {
            'uuid': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': 'sanborn',
            'contentdmPointer': 150,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'd29950d0-c451-0133-1d17-0050569601ca-2',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': '/162/2204/1601831/preservation/1601831_001.tif',
            'preservationMasterFilename': '1601831_001.tif',
            'preservationMasterUUID': 'd29950d0-c451-0133-1d17-0050569601ca-2',
            'accessMasterPathname': '/162/2204/1601831/access/1601831_001.jp2',
            'accessMasterFilename': '1601831_001.jp2',
            'accessMasterUUID': 'd25db810-c451-0133-1d17-0050569601ca-3',
            'variant': 'Page',
            'pageNumber': '1',
            'subpageNumber': nil,
            'latitude': '45.0000000',
            'longitude': '-120.0000000',
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '2',
            'Title': 'My Great Title',
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': 'My Great Description',
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': '/162/2204/1601831/preservation/1601831_002.tif',
            'preservationMasterFilename': '1601831_002.tif',
            'preservationMasterUUID': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'accessMasterPathname': '/162/2204/1601831/access/1601831_002.jp2',
            'accessMasterFilename': '1601831_002.jp2',
            'accessMasterUUID': 'd2650710-c451-0133-1d17-0050569601ca-1',
            'variant': 'Page',
            'pageNumber': '2',
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': 'cd2d4601-c451-0133-1d17-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '0',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        }
    ]
    collection = collections(:sanborn)

    set = item_sets(:sanborn)
    set.items = collection.items
    set.save!

    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_item_set(set)
  end

  private

  ##
  # @param header [Array]
  # @param values [Array<Hash<String,Object>>]
  # @return [String]
  #
  def to_tsv(header, values)
    header.join("\t") + ItemTsvExporter::LINE_BREAK +
        values.map { |v| v.values.join("\t") }.join(ItemTsvExporter::LINE_BREAK) +
        ItemTsvExporter::LINE_BREAK
  end

end