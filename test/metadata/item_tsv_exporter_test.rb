require 'test_helper'

class ItemTsvExporterTest < ActiveSupport::TestCase

  COMPOUND_OBJECT_1001 = {
      'uuid': '21353276-887c-0f2b-25a0-ed444003303f',
      'parentId': nil,
      'preservationMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1001/preservation/1001_001.tif',
      'preservationMasterFilename': '1001_001.tif',
      'preservationMasterUUID': '8ec70c33-75c9-4ba5-cd21-54a1211e5375',
      'accessMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1001/access/1001_001.jp2',
      'accessMasterFilename': '1001_001.jp2',
      'accessMasterUUID': '5ab5693f-3a20-8769-5622-ca2ff9850d50',
      'variant': nil,
      'pageNumber': nil,
      'subpageNumber': nil,
      'published': true,
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
  }
  COMPOUND_OBJECT_1002 = {
      'uuid': '6bc86d3b-e321-1a63-5172-fbf9a6e1aaab',
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
      'published': true,
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
  }
  COMPOUND_OBJECT_1002_PAGE1 = {
      'uuid': '6a1d73f2-3493-1ca8-80e5-84a49d524f92',
      'parentId': '6bc86d3b-e321-1a63-5172-fbf9a6e1aaab',
      'preservationMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1002/preservation/1002_001.tif',
      'preservationMasterFilename': '1002_001.tif',
      'preservationMasterUUID': '6a1d73f2-3493-1ca8-80e5-84a49d524f92',
      'accessMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1002/access/1002_001.jp2',
      'accessMasterFilename': '1002_001.jp2',
      'accessMasterUUID': 'f29d1764-904e-6f6b-1371-7c639c8a383a',
      'variant': 'Page',
      'pageNumber': '1',
      'subpageNumber': nil,
      'published': true,
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
  COMPOUND_OBJECT_1002_PAGE2 = {
      'uuid': '9dc25346-b83a-eb8a-ac2a-bdde98b5a374',
      'parentId': '6bc86d3b-e321-1a63-5172-fbf9a6e1aaab',
      'preservationMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1002/preservation/1002_002.tif',
      'preservationMasterFilename': '1002_002.tif',
      'preservationMasterUUID': '9dc25346-b83a-eb8a-ac2a-bdde98b5a374',
      'accessMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1002/access/1002_002.jp2',
      'accessMasterFilename': '1002_002.jp2',
      'accessMasterUUID': 'a9bdc6af-fecb-6ed9-2ca9-e577fd1455ed',
      'variant': 'Page',
      'pageNumber': '2',
      'subpageNumber': nil,
      'published': true,
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
  COMPOUND_OBJECT_1002_SUPPLEMENT = {
      'uuid': '96a95ca7-57b5-3901-1022-2093e33cba3f',
      'parentId': '6bc86d3b-e321-1a63-5172-fbf9a6e1aaab',
      'preservationMasterPathname': 'repositories/1/collections/3/file_groups/3/root/1002/supplementary/text.txt',
      'preservationMasterFilename': 'text.txt',
      'preservationMasterUUID': '96a95ca7-57b5-3901-1022-2093e33cba3f',
      'accessMasterPathname': nil,
      'accessMasterFilename': nil,
      'accessMasterUUID': nil,
      'variant': 'Supplement',
      'pageNumber': nil,
      'subpageNumber': nil,
      'published': true,
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

  setup do
    @instance = ItemTsvExporter.new
  end

  # items_in_collection()

  test 'items_in_collection works' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        published contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)
    expected_values = [
        COMPOUND_OBJECT_1001,
        COMPOUND_OBJECT_1002,
        COMPOUND_OBJECT_1002_SUPPLEMENT,
        COMPOUND_OBJECT_1002_PAGE1,
        COMPOUND_OBJECT_1002_PAGE2
    ]
    collection = collections(:compound_object)
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection)
  end

  test 'items_in_collection respects the only_undescribed argument' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        published contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)

    # There should not be any IGNORE column values > 0.
    expected_values = [
        COMPOUND_OBJECT_1002_SUPPLEMENT,
        COMPOUND_OBJECT_1002_PAGE1,
        COMPOUND_OBJECT_1002_PAGE2
    ]
    collection = collections(:compound_object)
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection, only_undescribed: true)
  end

  test 'items_in_collection respects the published_after and published_before
  arguments' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        published contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)

    collection = collections(:compound_object)
    item = items(:compound_object_1002)
    item.update!(published_at: Time.now)
    item = items(:compound_object_1002_page1)
    item.update!(published_at: 1.hour.ago)
    item = items(:compound_object_1002_page2)
    item.update!(published_at: Time.now + 1.hour)

    # all items in range
    expected_values = [COMPOUND_OBJECT_1002,
                       COMPOUND_OBJECT_1002_PAGE1,
                       COMPOUND_OBJECT_1002_PAGE2]
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection,
                                               published_after: 2.hours.ago,
                                               published_before: Time.now + 2.hours)
    # only middle item in range
    expected_values = [COMPOUND_OBJECT_1002]
    assert_equal to_tsv(expected_header, expected_values),
                 @instance.items_in_collection(collection,
                                               published_after: 30.minutes.ago,
                                               published_before: Time.now + 30.minutes)
  end

  # items_in_item_set()

  test 'items_in_item_set works' do
    expected_header = %w(uuid parentId preservationMasterPathname
        preservationMasterFilename preservationMasterUUID accessMasterPathname
        accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
        published contentdmAlias contentdmPointer IGNORE Title
        Coordinates Creator Date\ Created Description lcsh:Subject tgm:Subject)
    expected_values = [
        COMPOUND_OBJECT_1001,
        COMPOUND_OBJECT_1002,
        COMPOUND_OBJECT_1002_SUPPLEMENT,
        COMPOUND_OBJECT_1002_PAGE1,
        COMPOUND_OBJECT_1002_PAGE2
    ]
    collection = collections(:compound_object)
    set = item_sets(:one)
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