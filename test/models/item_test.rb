require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    @item = items(:item1)
    assert @item.valid?

    @collection = collections(:collection1)
    @tsv = File.read(__dir__ + '/../fixtures/repository/lincoln.tsv')
    @tsv_array = CSV.parse(@tsv, headers: true, col_sep: "\t").
        map{ |row| row.to_hash }
  end

  # Item.tsv_header()

  test 'tsv_header should return the correct columns' do
    cols = Item.tsv_header(@item.collection.metadata_profile).strip.split("\t")
    assert_equal 13, cols.length
    assert_equal 'uuid', cols[0]
    assert_equal 'parentId', cols[1]
    assert_equal 'preservationMasterPathname', cols[2]
    assert_equal 'accessMasterPathname', cols[3]
    assert_equal 'variant', cols[4]
    assert_equal 'pageNumber', cols[5]
    assert_equal 'subpageNumber', cols[6]
    assert_equal 'latitude', cols[7]
    assert_equal 'longitude', cols[8]
    assert_equal 'title', cols[9]
    assert_equal 'description', cols[10]
    assert_equal 'lcsh:subject', cols[11]
    assert_equal 'tgm:subject', cols[12]
  end

  test 'tsv_header should end with a line break' do
    assert Item.tsv_header(@item.collection.metadata_profile).
        end_with?(Item::TSV_LINE_BREAK)
  end

  # access_master_bytestream()

  test 'access_master_bytestream() should return the access master bytestream,
  or nil if none exists' do
    assert_equal Bytestream::Type::ACCESS_MASTER,
                 @item.access_master_bytestream.bytestream_type

    @item.bytestreams.destroy_all
    assert_nil @item.access_master_bytestream
  end

  # bib_id()

  test 'bib_id() should return the bibId element value, or nil if none exists' do
    assert_nil @item.bib_id

    @item.elements.build(name: 'bibId', value: 'cats')
    assert_equal 'cats', @item.bib_id
  end

  # collection_repository_id

  test 'collection_repository_id must be a UUID' do
    @item.collection_repository_id = 123
    assert !@item.valid?

    @item.collection_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # description()

  test 'description() should return the description element value, or nil if
  none exists' do
    @item.elements.destroy_all
    assert_nil @item.description

    @item.elements.build(name: 'description', value: 'cats')
    assert_equal 'cats', @item.description
  end

  # effective_representative_item()

  test 'effective_representative_item should return the representative item
        when it is assigned' do
    id = 'a53add10-5ca8-0132-3334-0050569601ca-7'
    @item.representative_item_repository_id = id
    assert_equal id, @item.effective_representative_item.repository_id
  end

  test 'effective_representative_item should return the first page when
        representative_item_repository_id is not set' do
    @item = items(:map_obj1)
    @item.representative_item_repository_id = nil
    assert_equal 'd29950d0-c451-0133-1d17-0050569601ca-2',
                 @item.effective_representative_item.repository_id
  end

  test 'effective_representative_item should return the first child when
        representative_item_repository_id is not set and the first child is
        not a page' do
    @item = items(:map_obj1)
    @item.representative_item_repository_id = nil
    @item.items.first.variant = nil
    assert_equal 'd29950d0-c451-0133-1d17-0050569601ca-2',
                 @item.effective_representative_item.repository_id
  end

  test 'effective_representative_item should return the instance when
        representative_item_repository_id is not set and it has no children' do
    @item = items(:map_obj1)
    @item.representative_item_repository_id = nil
    @item.items.delete_all
    assert_equal @item.repository_id,
                 @item.effective_representative_item.repository_id
  end

  # element()

  test 'element() should work' do
    assert_equal 'My Great Title', @item.element('title').value
    assert_nil @item.element('bogus')
  end

  # migrate_elements()

  test 'migrate_elements() should work' do
    source_elements = @item.elements.select{ |e| e.name == 'title' }
    dest_elements = @item.elements.select{ |e| e.name == 'test' }

    assert_equal 1, source_elements.length
    assert_equal 0, dest_elements.length

    @item.migrate_elements('title', 'test')
    @item.reload

    source_elements = @item.elements.select{ |e| e.name == 'title' }
    dest_elements = @item.elements.select{ |e| e.name == 'test' }

    assert_equal 0, source_elements.length
    assert_equal 1, dest_elements.length
  end

  # parent_repository_id

  test 'parent_repository_id must be a UUID' do
    @item.parent_repository_id = 123
    assert !@item.valid?

    @item.parent_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # preservation_master_bytestream()

  test 'preservation_master_bytestream() should return the preservation
  master bytestream, or nil if none exists' do
    assert_equal Bytestream::Type::PRESERVATION_MASTER,
                 @item.preservation_master_bytestream.bytestream_type

    @item.bytestreams.destroy_all
    assert_nil @item.preservation_master_bytestream
  end

  # repository_id

  test 'repository_id must be a UUID' do
    @item.repository_id = 123
    assert !@item.valid?

    @item.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # representative_item()

  test 'representative_item() should work properly' do
    # nil representative item
    assert_nil(@item.representative_item)
    # nonexistent representative item
    @item.representative_item_repository_id = 'bogus'
    assert_nil(@item.representative_item)
    # for an existent representative item, it should return the representative item
    col = Collection.find_by_repository_id('d250c1f0-5ca8-0132-3334-0050569601ca-8')
    assert_equal('MyString', col.representative_item_id)
  end

  # representative_item_repository_id

  test 'representative_item_repository_id must be a UUID' do
    @item.representative_item_repository_id = 123
    assert !@item.valid?

    @item.representative_item_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # save

  test 'save() should prune identical elements' do
    @item.elements.destroy_all
    # These are all unique and should survive.
    @item.elements.build(name: 'name1', value: 'value1',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'name1', value: 'value2',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'name2', value: 'value1',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'name2', value: 'value2',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'name3', value: 'value',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'name3', value: 'value',
                         vocabulary: vocabularies(:lcsh))

    # One of these should get pruned.
    @item.elements.build(name: 'prunable', value: 'value',
                         vocabulary: vocabularies(:uncontrolled))
    @item.elements.build(name: 'prunable', value: 'value',
                         vocabulary: vocabularies(:uncontrolled))

    assert_equal 8, @item.elements.length
    @item.save!
    assert_equal 7, @item.elements.count
  end

  # solr_id()

  test 'solr_id() should return the Solr document ID' do
    assert_equal @item.repository_id, @item.solr_id
  end

  # subtitle()

  test 'subtitle() should return the title element value, or nil if none
  exists' do
    @item.elements.destroy_all
    assert_nil @item.subtitle

    @item.elements.build(name: 'subtitle', value: 'cats')
    assert_equal 'cats', @item.subtitle
  end

  # title()

  test 'title() should return the title element value, or nil if none exists' do
    @item.elements.destroy_all
    assert_nil @item.title

    @item.elements.build(name: 'title', value: 'cats')
    assert_equal 'cats', @item.title
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
    assert doc[Item::SolrFields::COLLECTION_PUBLISHED]
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
    assert_equal @item.title, doc[Item::SolrFields::TITLE]
    assert_equal @item.variant, doc[Item::SolrFields::VARIANT]

    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    assert_equal bs.media_type, doc[Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE]
    assert_equal bs.repository_relative_pathname,
                 doc[Item::SolrFields::ACCESS_MASTER_PATHNAME]

    bs = @item.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    assert_equal bs.media_type,
                 doc[Item::SolrFields::PRESERVATION_MASTER_MEDIA_TYPE]
    assert_equal bs.repository_relative_pathname,
                 doc[Item::SolrFields::PRESERVATION_MASTER_PATHNAME]

    title = @item.elements.select{ |e| e.name == 'title' }.first
    assert_equal [title.value], doc[title.solr_multi_valued_field]
    description = @item.elements.select{ |e| e.name == 'description' }.first
    assert_equal [description.value], doc[description.solr_multi_valued_field]
    subjects = @item.elements.select{ |e| e.name == 'subject' }
    assert_equal subjects.map(&:value),
                 doc[subjects.first.solr_multi_valued_field]
  end

  # update_from_embedded_metadata

  test 'update_from_embedded_metadata should work' do
    @item = items(:iptc_item)
    @item.update_from_embedded_metadata

    assert_equal 1, @item.elements.
        select{ |e| e.name == 'creator' and e.value == 'JP Goguen' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'creator' and e.value == 'University of Illinois Library' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'date' and e.value == '2012-10-10T00:00:00Z' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'dateCreated' and e.value == '2012:10:10' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'title' and e.value == 'Illini Union Photographs Record Series 3707005' }.length
  end

  # update_from_tsv

  test 'update_from_tsv should work' do
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

    @item.update_from_tsv(row)

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

  test 'update_from_tsv should raise an error if given an invalid vocabulary prefix' do
    row = {}
    row['title'] = 'Cats'
    row['bogus:subject'] = 'Felines'

    assert_raises RuntimeError do
      @item.update_from_tsv(row)
    end
  end

  # update_from_xml

  test 'update_from_xml should work with schema version 3' do
    xml = '<?xml version="1.0" encoding="utf-8"?>'
    xml += '<dls:Object xmlns:dls="http://digital.library.illinois.edu/terms#">'
    # technical elements
    xml += '<dls:repositoryId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:repositoryId>'
    xml += '<dls:collectionId>d250c1f0-5ca8-0132-3334-0050569601ca-8</dls:collectionId>' # from fixture
    xml += '<dls:parentId>ace52312-5ca8-0132-3334-0050569601ca-8</dls:parentId>'
    xml += '<dls:representativeItemId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:representativeItemId>'
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

    assert_equal('d250c1f0-5ca8-0132-3334-0050569601ca-8', @item.collection.repository_id)
    assert_equal(1984, @item.date.year)
    assert_equal('full text', @item.full_text)
    assert_equal(45.52, @item.latitude)
    assert_equal(-120.564, @item.longitude)
    assert_equal(3, @item.page_number)
    assert_equal('ace52312-5ca8-0132-3334-0050569601ca-8', @item.parent_repository_id)
    assert @item.published
    assert_equal('e12adef0-5ca8-0132-3334-0050569601ca-8', @item.repository_id)
    assert_equal('e12adef0-5ca8-0132-3334-0050569601ca-8', @item.representative_item_repository_id)
    assert_equal(1, @item.subpage_number)
    assert_equal(Item::Variants::PAGE, @item.variant)

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'More cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Even more cats' }.length

    assert_equal('Cats', @item.title)
  end

end
