require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  def setup
    @item = items(:item1)
  end

  # Item.from_dls_xml()

  test 'from_dls_xml() should return an item' do
    xml = File.read(__dir__ + '/../fixtures/repository/image/item_1.xml')
    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'
    assert_kind_of Item, Item.from_dls_xml(doc, 1)
  end

  # access_master_bytestream()

  test 'access_master_bytestream() should work properly' do
    assert_equal Bytestream::Type::ACCESS_MASTER,
                 @item.access_master_bytestream.bytestream_type
  end

  # preservation_master_bytestream()

  test 'preservation_master_bytestream() should work properly' do
    assert_equal Bytestream::Type::PRESERVATION_MASTER,
                 @item.preservation_master_bytestream.bytestream_type
  end

  # representative_item()

  test 'representative_item() should work properly' do
    # nil representative item
    assert_nil(@item.representative_item)
    # nonexistent representative item
    @item.representative_item_repository_id = 'bogus'
    assert_nil(@item.representative_item)
    # for an existent representative item, it should return the representative item
    col = Collection.find_by_repository_id('collection1')
    assert_equal('MyString', col.representative_item_id)
  end

  # to_dls_xml(schema_version)

  test 'to_dls_xml() should work with version 1' do
    Item.all.each do |item|
      xml = item.to_dls_xml(1)
      doc = Nokogiri::XML(xml, &:noblanks)
      schema_path = sprintf('%s/../../public/schema/1/object.xsd', __dir__)
      xsd = Nokogiri::XML::Schema(File.read(schema_path))
      xsd.validate(doc).each do |error|
        raise error.message
      end
    end
  end

  test 'to_dls_xml() should work with version 2' do
    Item.all.each do |item|
      xml = item.to_dls_xml(2)
      doc = Nokogiri::XML(xml, &:noblanks)
      schema_path = sprintf('%s/../../public/schema/2/object.xsd', __dir__)
      xsd = Nokogiri::XML::Schema(File.read(schema_path))
      xsd.validate(doc).each do |error|
        raise error.message
      end
    end
  end

  # update_from_tsv

  test 'update_from_tsv should work' do
    row = {}
    # technical elements
    row['collectionId'] = 'collection1' # from fixture
    row['date'] = '1984'
    row['fullText'] = 'full text'
    row['latitude'] = '45.52'
    row['longitude'] = '-120.564'
    row['pageNumber'] = '3'
    row['parentId'] = 'item1'
    row['published'] = 'true'
    row['repositoryId'] = 'cats001'
    row['representativeItemId'] = 'cats001'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE
    row['accessMasterPathname'] = '/pathname'
    row['accessMasterWidth'] = '500'
    row['accessMasterHeight'] = '400'
    row['accessMasterMediaType'] = 'image/jpeg'
    row['preservationMasterPathname'] = '/pathname'
    row['preservationMasterWidth'] = '500'
    row['preservationMasterHeight'] = '400'
    row['preservationMasterMediaType'] = 'image/jpeg'

    # descriptive elements
    row['description'] = sprintf('Cats%scats%sand more cats',
                                 Item::MULTI_VALUE_SEPARATOR,
                                 Item::MULTI_VALUE_SEPARATOR)
    row['title'] = 'Cats'

    @item.update_from_tsv(row)

    assert_equal('collection1', @item.collection.repository_id)
    assert_equal(1984, @item.date.year)
    assert_equal('full text', @item.full_text)
    assert_equal(45.52, @item.latitude)
    assert_equal(-120.564, @item.longitude)
    assert_equal(3, @item.page_number)
    assert_equal('item1', @item.parent_repository_id)
    assert @item.published
    assert_equal('cats001', @item.repository_id)
    assert_equal('cats001', @item.representative_item_repository_id)
    assert_equal(1, @item.subpage_number)
    assert_equal(Item::Variants::PAGE, @item.variant)

    assert_equal(2, @item.bytestreams.length)
    am = @item.bytestreams.
        select{ |bs| bs.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal('/pathname', am.file_group_relative_pathname)
    assert_equal(500, am.width)
    assert_equal(400, am.height)
    assert_equal('image/jpeg', am.media_type)

    am = @item.bytestreams.
        select{ |bs| bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal('/pathname', am.file_group_relative_pathname)
    assert_equal(500, am.width)
    assert_equal(400, am.height)
    assert_equal('image/jpeg', am.media_type)

    assert_equal('A lot of cats', @item.description)
    assert_equal('Cats', @item.title)
  end

end
