require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    @item = items(:item1)

    @free_form_collection = collections(:collection1)
    @medusa_free_form_tsv = File.read(__dir__ + '/../fixtures/repository/medusa-free-form.tsv')
    @medusa_free_form_tsv_array = CSV.parse(@medusa_free_form_tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }

    @map_collection = collections(:collection2)
    @medusa_map_tsv = File.read(__dir__ + '/../fixtures/repository/medusa-map.tsv')
    @medusa_map_tsv_array = CSV.parse(@medusa_map_tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }
  end

  # Item.from_dls_xml()

  test 'from_dls_xml() should return an item' do
    xml = File.read(__dir__ + '/../fixtures/repository/image/item_1.xml')
    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'
    assert_kind_of Item, Item.from_dls_xml(doc, 3)
  end

  # Item.tsv_header()

  test 'tsv_header should return the correct columns' do
    cols = Item.tsv_header(@item.collection.metadata_profile).strip.split("\t")
    assert_equal 'uuid', cols[0]
    assert_equal 'parentId', cols[1]
    assert_equal 'variant', cols[2]
    assert_equal 'pageNumber', cols[3]
    assert_equal 'subpageNumber', cols[4]
    assert_equal 'latitude', cols[5]
    assert_equal 'longitude', cols[6]

    @item.collection.metadata_profile.element_defs.map(&:name).each_with_index do |el, index|
      assert_not_empty cols[7 + index]
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

  test 'to_dls_xml() should work with version 3' do
    Item.all.each do |item|
      xml = item.to_dls_xml(3)
      doc = Nokogiri::XML(xml, &:noblanks)
      schema_path = sprintf('%s/../../public/schema/3/object.xsd', __dir__)
      xsd = Nokogiri::XML::Schema(File.read(schema_path))
      xsd.validate(doc).each do |error|
        raise error.message
      end
    end
  end

  # to_solr

  test 'to_solr should work' do
    doc = @item.to_solr

    assert_equal @item.solr_id, doc[Item::SolrFields::ID]
    assert_equal @item.class.to_s, doc[Item::SolrFields::CLASS]
    assert_equal @item.collection_repository_id,
                 doc[Item::SolrFields::COLLECTION]
    assert_equal @item.date.utc.iso8601, doc[Item::SolrFields::DATE]
    assert_equal @item.full_text, doc[Item::SolrFields::FULL_TEXT]
    assert_not_empty doc[Item::SolrFields::LAST_INDEXED]
    assert_equal "#{@item.latitude},#{@item.longitude}",
                 doc[Item::SolrFields::LAT_LONG]
    assert_equal @item.page_number, doc[Item::SolrFields::PAGE_NUMBER]
    assert_equal @item.parent_repository_id, doc[Item::SolrFields::PARENT_ITEM]
    assert_equal @item.published, doc[Item::SolrFields::PUBLISHED]
    assert_equal @item.representative_item_repository_id,
                 doc[Item::SolrFields::REPRESENTATIVE_ITEM_ID]
    assert_equal @item.subpage_number, doc[Item::SolrFields::SUBPAGE_NUMBER]
    assert_equal @item.variant, doc[Item::SolrFields::VARIANT]

    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal bs.media_type, doc[Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE]

    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal bs.media_type,
                 doc[Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE]

    @item.elements.each do |element|
      assert_equal [element.value], doc[element.solr_multi_valued_field]
      assert_equal element.value, doc[element.solr_single_valued_field]
    end
  end

  # to_tsv

  test 'to_tsv should work' do
    values = @item.to_tsv.strip.split("\t")
    assert_equal @item.repository_id.to_s, values[0]
    assert_equal @item.parent_repository_id.to_s, values[1]
    assert_equal @item.variant.to_s, values[2]
    assert_equal @item.page_number.to_s, values[3]
    assert_equal @item.subpage_number.to_s, values[4]
    assert_equal @item.latitude.to_s, values[5]
    assert_equal @item.longitude.to_s, values[6]

    @item.collection.metadata_profile.element_defs.each_with_index do |el, index|
      assert_equal @item.elements.select{ |e| e.name == el.name }.map(&:value).
          join(Item::MULTI_VALUE_SEPARATOR),
                   values[7 + index].to_s
      assert_not_equal 'nil', values[7 + index]
    end
  end

  # update_from_tsv

  test 'update_from_tsv should work with a parentId column' do
    row = {}
    # technical elements
    row['parentId'] = '9182'
    row['date'] = '1984'
    row['latitude'] = '45.52'
    row['longitude'] = '-120.564'
    row['pageNumber'] = '3'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE

    # descriptive elements
    row['description'] = sprintf('Cats%scats%sand more cats',
                                 Item::MULTI_VALUE_SEPARATOR,
                                 Item::MULTI_VALUE_SEPARATOR)
    row['title'] = 'Cats'

    @item.update_from_tsv([row], row)

    assert_equal('9182', @item.parent_repository_id)
    assert_equal(1984, @item.date.year)
    assert_equal(45.52, @item.latitude)
    assert_equal(-120.564, @item.longitude)
    assert_equal(3, @item.page_number)
    assert_equal(1, @item.subpage_number)
    assert_equal(Item::Variants::PAGE, @item.variant)

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'and more cats' }.length

    assert_equal('Cats', @item.title)
  end

  test 'update_from_tsv should work without a parentId column' do
    row = {}
    # technical elements
    row['date'] = '1984'
    row['latitude'] = '45.52'
    row['longitude'] = '-120.564'
    row['pageNumber'] = '3'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE

    # descriptive elements
    row['description'] = sprintf('Cats%scats%sand more cats',
                                 Item::MULTI_VALUE_SEPARATOR,
                                 Item::MULTI_VALUE_SEPARATOR)
    row['title'] = 'Cats'

    @item.update_from_tsv([row], row)

    assert_nil(@item.parent_repository_id)
    assert_equal(1984, @item.date.year)
    assert_equal(45.52, @item.latitude)
    assert_equal(-120.564, @item.longitude)
    assert_equal(3, @item.page_number)
    assert_equal(1, @item.subpage_number)
    assert_equal(Item::Variants::PAGE, @item.variant)

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'and more cats' }.length

    assert_equal('Cats', @item.title)
  end

  test 'update_from_tsv should set the variant for free-form content from
        Medusa TSV' do
    ItemTsvIngester.new.ingest_tsv(@medusa_free_form_tsv, @free_form_collection)

    item1 = Item.find_by_repository_id('a53a0ce0-5ca8-0132-3334-0050569601ca-9')
    item1.update_from_tsv(@medusa_free_form_tsv_array,
                          { 'inode_type' => 'folder' })
    assert_equal Item::Variants::DIRECTORY, item1.variant

    item2 = Item.find_by_repository_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
    item2.update_from_tsv(@medusa_free_form_tsv_array,
                          { 'inode_type' => 'file' })
    assert_equal Item::Variants::FILE, item2.variant
  end

  test 'update_from_tsv should not set the variant for non-free-form compound
        objects from Medusa TSV if it is missing' do
    ItemTsvIngester.new.ingest_tsv(@medusa_map_tsv, @map_collection)

    item = Item.find_by_repository_id('abdc55a0-c451-0133-1d17-0050569601ca-1')
    item.update_from_tsv(@medusa_map_tsv_array, {})
    assert_nil item.variant
  end

  test 'update_from_tsv should set the variant for non-free-form pages from
        Medusa TSV if it is missing' do
    ItemTsvIngester.new.ingest_tsv(@medusa_map_tsv, @map_collection)

    item = Item.find_by_repository_id('d29edba0-c451-0133-1d17-0050569601ca-c')
    item.update_from_tsv(@medusa_map_tsv_array, {})
    assert_equal Item::Variants::PAGE, item.variant
  end

  test 'update_from_tsv should set the title for title-less free-form content
        from Medusa TSV' do
    ItemTsvIngester.new.ingest_tsv(@medusa_free_form_tsv, @free_form_collection)

    item1 = Item.find_by_repository_id('a53a0ce0-5ca8-0132-3334-0050569601ca-9')
    item1.update_from_tsv(@medusa_free_form_tsv_array,
                          { 'name' => 'binder_9' })
    assert_equal 'binder_9', item1.title

    item2 = Item.find_by_repository_id('6e3c33c0-5ce3-0132-3334-0050569601ca-f')
    item2.update_from_tsv(@medusa_free_form_tsv_array,
                          { 'name' => 'animals_001.jpg' })
    assert_equal 'animals_001.jpg', item2.title
  end

  # update_from_xml

  test 'update_from_xml should work with schema version 3' do
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

    @item.update_from_xml(doc, 3)

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
    assert_equal('/pathname', bs.repository_relative_pathname)
    assert_equal(500, bs.width)
    assert_equal(400, bs.height)
    assert_equal('image/jpeg', bs.media_type)

    bs = @item.bytestreams.
        select{ |bs| bs.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal('/pathname', bs.repository_relative_pathname)
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
