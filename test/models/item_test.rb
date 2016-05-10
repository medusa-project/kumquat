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

  # Item.tsv_header()

  test 'tsv_header should return the correct columns' do
    cols = Item.tsv_header.strip.split("\t")
    assert_equal 'repositoryId', cols[0]
    assert_equal 'parentId', cols[1]
    assert_equal 'collectionId', cols[2]
    assert_equal 'representativeItemId', cols[3]
    assert_equal 'variant', cols[4]
    assert_equal 'pageNumber', cols[5]
    assert_equal 'subpageNumber', cols[6]
    assert_equal 'fullText', cols[7]
    assert_equal 'accessMasterPathname', cols[8]
    assert_equal 'accessMasterURL', cols[9]
    assert_equal 'accessMasterMediaType', cols[10]
    assert_equal 'accessMasterWidth', cols[11]
    assert_equal 'accessMasterHeight', cols[12]
    assert_equal 'preservationMasterPathname', cols[13]
    assert_equal 'preservationMasterURL', cols[14]
    assert_equal 'preservationMasterMediaType', cols[15]
    assert_equal 'preservationMasterWidth', cols[16]
    assert_equal 'preservationMasterHeight', cols[17]
    assert_equal 'created', cols[18]
    assert_equal 'lastModified', cols[19]

    Element.all_descriptive.map(&:name).each_with_index do |el, index|
      assert_not_empty cols[20 + index]
    end
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

  # to_tsv

  test 'to_tsv should work' do
    values = @item.to_tsv.strip.split("\t")
    assert_equal @item.repository_id.to_s, values[0]
    assert_equal @item.parent_repository_id.to_s, values[1]
    assert_equal @item.collection_repository_id.to_s, values[2]
    assert_equal @item.representative_item_repository_id.to_s, values[3]
    assert_equal @item.variant.to_s, values[4]
    assert_equal @item.page_number.to_s, values[5]
    assert_equal @item.subpage_number.to_s, values[6]
    assert_equal @item.full_text.to_s, values[7]
    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal bs&.file_group_relative_pathname.to_s, values[8]
    assert_equal bs&.url.to_s, values[9]
    assert_equal bs&.media_type.to_s, values[10]
    assert_equal bs&.width.to_s, values[11]
    assert_equal bs&.height.to_s, values[12]
    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal bs&.file_group_relative_pathname.to_s, values[13]
    assert_equal bs&.url.to_s, values[14]
    assert_equal bs&.media_type.to_s, values[15]
    assert_equal bs&.width.to_s, values[16]
    assert_equal bs&.height.to_s, values[17]
    assert_equal @item.created_at.utc.iso8601, values[18]
    assert_equal @item.updated_at.utc.iso8601, values[19]

    Element.all_descriptive.each_with_index do |el, index|
      assert_equal @item.elements.select{ |e| e.name == el.name }.map(&:value).
          join(Item::MULTI_VALUE_SEPARATOR),
                   values[20 + index].to_s
      assert_not_equal 'nil', values[20 + index]
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

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'and more cats' }.length

    assert_equal('Cats', @item.title)
  end

  # update_from_xml

  test 'update_from_xml should work with schema version 1' do
    # TODO: write this
  end

  test 'update_from_xml should work with schema version 2' do
    xml = '<?xml version="1.0" encoding="utf-8"?>'
    xml += '<dls:Object xmlns:dls="http://digital.library.illinois.edu/terms#">'
    # technical elements
    xml += '<dls:repositoryId>cats001</dls:repositoryId>'
    xml += '<dls:collectionId>collection1</dls:collectionId>' # from fixture
    xml += '<dls:parentId>item1</dls:parentId>'
    xml += '<dls:representativeItemId>cats001</dls:representativeItemId>'
    xml += '<dls:published>true</dls:published>'
    xml += '<dls:fullText>full text</dls:fullText>'
    xml += '<dls:pageNumber>3</dls:pageNumber>'
    xml += '<dls:subpageNumber>1</dls:subpageNumber>'
    xml += '<dls:latitude>45.52</dls:latitude>'
    xml += '<dls:longitude>-120.564</dls:longitude>'
    xml += "<dls:variant>#{Item::Variants::PAGE}</dls:variant>"
    xml += '<dls:accessMasterPathname>/pathname</dls:accessMasterPathname>'
    xml += '<dls:accessMasterMediaType>image/jpeg</dls:accessMasterMediaType>'
    xml += '<dls:accessMasterWidth>500</dls:accessMasterWidth>'
    xml += '<dls:accessMasterHeight>400</dls:accessMasterHeight>'
    xml += '<dls:preservationMasterPathname>/pathname</dls:preservationMasterPathname>'
    xml += '<dls:preservationMasterMediaType>image/jpeg</dls:preservationMasterMediaType>'
    xml += '<dls:preservationMasterWidth>500</dls:preservationMasterWidth>'
    xml += '<dls:preservationMasterHeight>400</dls:preservationMasterHeight>'

    # descriptive elements
    xml += '<dls:date>1984</dls:date>'
    xml += '<dls:description>Cats</dls:description>'
    xml += '<dls:description>More cats</dls:description>'
    xml += '<dls:description>Even more cats</dls:description>'
    xml += '<dls:title>Cats</dls:title>'
    xml += '</dls:Object>'

    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'

    @item.update_from_xml(doc, 2)

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
    bs = @item.bytestreams.
        select{ |bs| bs.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal('/pathname', bs.file_group_relative_pathname)
    assert_equal(500, bs.width)
    assert_equal(400, bs.height)
    assert_equal('image/jpeg', bs.media_type)

    bs = @item.bytestreams.
        select{ |bs| bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal('/pathname', bs.file_group_relative_pathname)
    assert_equal(500, bs.width)
    assert_equal(400, bs.height)
    assert_equal('image/jpeg', bs.media_type)

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'More cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Even more cats' }.length

    assert_equal('Cats', @item.title)
  end

end
