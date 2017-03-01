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
    assert_equal 17, cols.length
    assert_equal 'uuid', cols[0]
    assert_equal 'parentId', cols[1]
    assert_equal 'preservationMasterPathname', cols[2]
    assert_equal 'preservationMasterFilename', cols[3]
    assert_equal 'accessMasterPathname', cols[4]
    assert_equal 'accessMasterFilename', cols[5]
    assert_equal 'variant', cols[6]
    assert_equal 'pageNumber', cols[7]
    assert_equal 'subpageNumber', cols[8]
    assert_equal 'latitude', cols[9]
    assert_equal 'longitude', cols[10]
    assert_equal 'contentdmAlias', cols[11]
    assert_equal 'contentdmPointer', cols[12]
    assert_equal 'title', cols[13]
    assert_equal 'description', cols[14]
    assert_equal 'lcsh:subject', cols[15]
    assert_equal 'tgm:subject', cols[16]
  end

  test 'tsv_header should end with a line break' do
    assert Item.tsv_header(@item.collection.metadata_profile).
        end_with?(Item::TSV_LINE_BREAK)
  end

  # access_master_binary()

  test 'access_master_binary() should return the access master binary, or nil
  if none exists' do
    assert_equal Binary::Type::ACCESS_MASTER,
                 @item.access_master_binary.binary_type

    @item.binaries.destroy_all
    assert_nil @item.access_master_binary
  end

  # as_json()

  test 'as_json() should return the correct structure' do
    struct = @item.as_json
    assert_equal @item.repository_id, struct['repository_id']
    # We'll trust that all the other properties are there.
    assert_equal 5, struct['elements'].length
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
    @item.save
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
    assert_equal 'be8d3500-c451-0133-1d17-0050569601ca-9',
                 @item.effective_representative_item.repository_id
  end

  test 'effective_representative_item should return the instance when
        representative_item_repository_id is not set and it has no pages' do
    @item = items(:map_obj1)
    @item.representative_item_repository_id = nil
    @item.items.delete_all
    assert_equal @item.repository_id,
                 @item.effective_representative_item.repository_id
  end

  # effective_rights_statement()

  test 'effective_rights_statement() should return the statement of the instance' do
    assert_equal 'Sample Rights', @item.effective_rights_statement
  end

  test 'effective_rights_statement() should fall back to a parent statement' do
    @item = items(:free_form_dir1_file1)
    assert_equal 'Sample Rights', @item.effective_rights_statement
  end

  test 'effective_rights_statement() should fall back to the collection
  rights statement' do
    @item.elements.destroy_all
    @item.save
    @item.collection.rights_statement = 'cats'
    assert_equal 'cats', @item.effective_rights_statement
  end

  # effective_rightsstatement_org_statement()

  test 'effective_rightsstatements_org_statement() should return the statement
  of the instance' do
    @item.elements.build(name: 'accessRights',
                         uri: 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/')
    assert_equal 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
                 @item.effective_rightsstatements_org_statement.uri
  end

  test 'effective_rightsstatements_org_statement() should fall back to a parent
  statement' do
    @item = items(:free_form_dir1_file1)
    @item.elements.where(name: 'accessRights').destroy_all
    @item.parent.elements.build(name: 'accessRights',
                                uri: 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/')
    assert_equal 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
                 @item.effective_rightsstatements_org_statement.uri
  end

  test 'effective_rightsstatements_org_statement() should fall back to the
  collection rights statement' do
    @item.elements.where(name: 'accessRights').destroy_all
    @item.collection.rightsstatements_org_uri =
        'http://rightsstatements.org/vocab/NoC-OKLR/1.0/'
    assert_equal 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
                 @item.effective_rightsstatements_org_statement.uri
  end

  # element()

  test 'element() should work' do
    assert_equal 'My Great Title', @item.element('title').value
    assert_nil @item.element('bogus')
  end

  # iiif_identifier()

  test 'iiif_identifier should use the access master binary by default' do
    @item.access_master_binary.repository_relative_pathname = '/bla/bla/cats cats.jpg'
    @item.access_master_binary.media_type = 'image/jpeg'
    @item.binaries.where(binary_type: Binary::Type::PRESERVATION_MASTER).destroy_all
    assert_equal 'bla/bla/cats cats.jpg', @item.iiif_image_binary.iiif_image_identifier
  end

  test 'iiif_identifier should fall back to the preservation master binary' do
    @item.binaries.where(binary_type: Binary::Type::ACCESS_MASTER).destroy_all
    @item.preservation_master_binary.repository_relative_pathname = '/bla/bla/cats cats.jpg'
    @item.preservation_master_binary.media_type = 'image/jpeg'
    assert_equal 'bla/bla/cats cats.jpg', @item.iiif_image_binary.iiif_image_identifier
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

  # preservation_master_binary()

  test 'preservation_master_binary() should return the preservation
  master binary, or nil if none exists' do
    assert_equal Binary::Type::PRESERVATION_MASTER,
                 @item.preservation_master_binary.binary_type

    @item.binaries.destroy_all
    assert_nil @item.preservation_master_binary
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

  test 'save() should copy allowed_roles and denied_roles into
  effective_allowed_roles and effective_denied_roles when they exist' do
    item = items(:map_obj1_page1)

    # Create initial allowed and denied roles.
    item.allowed_roles << roles(:admins)
    item.denied_roles << roles(:users)
    # Assert that they get propagated to effective roles.
    item.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'admins', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'users', item.effective_denied_roles.first.key

    # Clear them out and change them.
    item.allowed_roles.destroy_all
    item.allowed_roles << roles(:skiers)
    item.denied_roles.destroy_all
    item.denied_roles << roles(:cellists)
    # Assert that they get propagated to effective roles.
    item.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'skiers', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'cellists', item.effective_denied_roles.first.key
  end

  test 'save() should copy parent allowed_roles and denied_roles into
  effective_allowed_roles and effective_denied_roles when they are not set on
  the instance' do
    item = items(:map_obj1_page1)

    # Create initial allowed and denied roles.
    item.parent.allowed_roles << roles(:admins)
    item.parent.denied_roles << roles(:users)

    # Assert that they get propagated to effective roles.
    item.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'admins', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'users', item.effective_denied_roles.first.key
  end

  test 'save() should copy collection allowed_roles and denied_roles into
  effective_allowed_roles and effective_denied_roles when they are not set on
  the instance nor a parent' do
    item = items(:map_obj1_page1)

    # Create initial allowed and denied roles.
    item.collection.allowed_roles << roles(:admins)
    item.collection.denied_roles << roles(:users)

    # Assert that they get propagated to effective roles.
    item.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'admins', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'users', item.effective_denied_roles.first.key
  end

  test 'save() should propagate allowed_roles and denied_roles into
  effective_allowed_roles and effective_denied_roles of children' do
    item = items(:map_obj1_page1)
    parent = item.parent

    parent.allowed_roles << roles(:admins)
    parent.denied_roles << roles(:users)

    # Assert that they get propagated to child effective roles.
    parent.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'admins', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'users', item.effective_denied_roles.first.key
  end

  # solr_id()

  test 'solr_id() should return the Solr document ID' do
    assert_equal @item.repository_id, @item.solr_id
  end

  # subtitle()

  test 'subtitle() should return the title element value, or nil if none
  exists' do
    @item.elements.destroy_all
    @item.save
    assert_nil @item.subtitle

    @item.elements.build(name: 'alternativeTitle', value: 'cats')
    @item.save
    assert_equal 'cats', @item.subtitle
  end

  # title()

  test 'title() should return the title element value, or nil if none exists' do
    @item.elements.destroy_all
    @item.save
    assert_equal 'a1234567-5ca8-0132-3334-0050569601ca-8', @item.title

    @item.elements.build(name: 'title', value: 'cats')
    @item.save
    assert_equal 'cats', @item.title
  end

  # to_dls_xml(schema_version)

  test 'to_dls_xml() should work with version 3' do
    Item.all.each do |item|
      xml = item.to_dls_xml(3)
      doc = Nokogiri::XML(xml, &:noblanks)
      # TODO: write this
    end
  end

  # to_solr

  test 'to_solr should work' do
    doc = @item.to_solr

    assert_equal @item.solr_id, doc[Item::SolrFields::ID]
    assert_equal @item.class.to_s, doc[Item::SolrFields::CLASS]
    assert_equal @item.collection_repository_id,
                 doc[Item::SolrFields::COLLECTION]
    assert_equal "#{@item.repository_id}-000000-ZZZZZZ-ZZZZZZ-#{@item.title}",
                 doc[Item::SolrFields::GROUPED_SORT]
    assert doc[Item::SolrFields::COLLECTION_PUBLISHED]
    assert_equal @item.date.utc.iso8601, doc[Item::SolrFields::DATE]
    assert_equal @item.effective_allowed_roles.map(&:key),
                 doc[Item::SolrFields::EFFECTIVE_ALLOWED_ROLES]
    assert_equal @item.effective_denied_roles.map(&:key),
                 doc[Item::SolrFields::EFFECTIVE_DENIED_ROLES]
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
    assert_equal 246, doc[Item::SolrFields::TOTAL_BYTE_SIZE]
    assert_equal @item.variant, doc[Item::SolrFields::VARIANT]

    bs = @item.binaries.
        select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER }.first
    assert_equal bs.media_type, doc[Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE]
    assert_equal bs.repository_relative_pathname,
                 doc[Item::SolrFields::ACCESS_MASTER_PATHNAME]

    bs = @item.binaries.
        select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER }.first
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
    @item.update_from_embedded_metadata(include_date_created: true)

    assert_equal 1, @item.elements.
        select{ |e| e.name == 'title' and e.value == 'Illini Union Photographs Record Series 3707005' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'creator' and e.value == 'University of Illinois Library' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'dateCreated' and e.value == '2012-10-10' }.length
    assert_equal '2012-10-10T00:00:00Z', @item.date.iso8601
  end

  # update_from_tsv

  test 'update_from_tsv should work' do
    row = {}
    # technical elements
    row['contentdmAlias'] = 'cats'
    row['contentdmPointer'] = '123'
    row['date'] = '1984'
    row['latitude'] = '45.52'
    row['longitude'] = '-120.564'
    row['pageNumber'] = '3'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE

    # descriptive elements
    row['description'] = 'Cats' +
        Item::TSV_MULTI_VALUE_SEPARATOR +
        'cats' + Item::TSV_URI_VALUE_SEPARATOR + '<http://example.org/cats1>' +
        Item::TSV_MULTI_VALUE_SEPARATOR +
        'and more cats' + Item::TSV_URI_VALUE_SEPARATOR + '<http://example.org/cats2>'
    row['title'] = 'Cats & Stuff'
    row['lcsh:subject'] = 'Cats'

    @item.update_from_tsv(row)

    assert_equal 'cats', @item.contentdm_alias
    assert_equal 123, @item.contentdm_pointer
    assert_equal 1984, @item.date.year
    assert_equal 45.52, @item.latitude
    assert_equal -120.564, @item.longitude
    assert_equal 3, @item.page_number
    assert_equal 1, @item.subpage_number
    assert_equal Item::Variants::PAGE, @item.variant

    assert_equal 6, @item.elements.length # all of the above plus date
    assert_equal 1, @item.elements.select{ |e| e.name == 'title' and
        e.value == 'Cats & Stuff' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'description' and
        e.value == 'cats' and e.uri == 'http://example.org/cats1' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'description' and
        e.value == 'and more cats' and e.uri == 'http://example.org/cats2' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'subject' and
        e.value == 'Cats' and e.vocabulary == vocabularies(:lcsh) }.length
  end

  test 'update_from_tsv should auto-normalize date from date or dateCreated
  elements' do
    row = { 'date' => '1995-02-23' }
    @item.update_from_tsv(row)
    assert_equal 1995, @item.date.year

    row = { 'dateCreated' => '1992-01-13' }
    @item.update_from_tsv(row)
    assert_equal 1992, @item.date.year
  end

  test 'update_from_tsv should auto-normalize lat/long from coordinates element
  when latitude and longitude columns are empty' do
    row = { 'coordinates' => 'W 90⁰26\'05"/ N 40⁰39\'51"' }
    @item.update_from_tsv(row)
    assert_equal 39.25243, @item.latitude.to_f
    assert_equal -152.23423, @item.longitude.to_f
  end

  test 'update_from_tsv should raise an error if given an invalid element name' do
    row = {}
    row['title'] = 'Cats'
    row['totallyBogus'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

  test 'update_from_tsv should raise an error if given an invalid vocabulary prefix' do
    row = {}
    row['title'] = 'Cats'
    row['bogus:subject'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

  # update_from_xml

  test 'update_from_xml should work' do
    xml = '<?xml version="1.0" encoding="utf-8"?>'
    xml += '<dls:Object xmlns:dls="http://digital.library.illinois.edu/terms#">'
    # technical elements
    xml += '<dls:repositoryId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:repositoryId>'
    xml += '<dls:representativeItemId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:representativeItemId>'
    xml += '<dls:published>true</dls:published>'
    xml += '<dls:fullText>full text</dls:fullText>'
    xml += '<dls:pageNumber>3</dls:pageNumber>'
    xml += '<dls:subpageNumber>1</dls:subpageNumber>'
    xml += '<dls:latitude>45.52</dls:latitude>'
    xml += '<dls:longitude>-120.564</dls:longitude>'
    xml += "<dls:variant>#{Item::Variants::PAGE}</dls:variant>"
    xml += '<dls:contentdmAlias>cats</dls:contentdmAlias>'
    xml += '<dls:contentdmPointer>123</dls:contentdmPointer>'
    xml += '<dls:allowedRoles>'
    xml +=   '<key>admins</key>'
    xml += '</dls:allowedRoles>'
    xml += '<dls:deniedRoles>'
    xml +=   '<key>users</key>'
    xml += '</dls:deniedRoles>'

    # descriptive elements
    xml += '<dls:date vocabularyKey="uncontrolled" dataType="string">1984</dls:date>'
    xml += '<dls:description vocabularyKey="uncontrolled" dataType="string">Cats</dls:description>'
    xml += '<dls:description vocabularyKey="lcsh" dataType="string">More cats</dls:description>'
    xml += '<dls:description vocabularyKey="uncontrolled" dataType="URI">http://example.org/cats</dls:description>'
    xml += '<dls:title vocabularyKey="uncontrolled" dataType="string">Cats</dls:title>'
    xml += '</dls:Object>'

    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'

    @item.update_from_xml(doc, 3)

    assert_equal 'cats', @item.contentdm_alias
    assert_equal 123, @item.contentdm_pointer
    assert_equal 1984, @item.date.year
    assert_equal 'full text', @item.full_text
    assert_equal 45.52, @item.latitude
    assert_equal -120.564, @item.longitude
    assert_equal 3, @item.page_number
    assert @item.published
    assert_equal 'e12adef0-5ca8-0132-3334-0050569601ca-8', @item.repository_id
    assert_equal 'e12adef0-5ca8-0132-3334-0050569601ca-8', @item.representative_item_repository_id
    assert_equal 1, @item.subpage_number
    assert_equal Item::Variants::PAGE, @item.variant
    assert_equal 1, @item.allowed_roles.length
    assert_equal 'admins', @item.allowed_roles.first.key
    assert_equal 1, @item.denied_roles.length
    assert_equal 'users', @item.denied_roles.first.key

    descriptions = @item.elements.select{ |e| e.name == 'description' }
    assert_equal 3, descriptions.length
    assert_equal 1, descriptions.select{ |e| e.value == 'Cats' }.length
    assert_equal 1, descriptions.select{ |e| e.value == 'More cats' }.length
    assert_equal 1, descriptions.select{ |e| e.uri == 'http://example.org/cats' }.length
    assert_equal 'uncontrolled', descriptions.first.vocabulary.key
    assert_equal 'lcsh', descriptions[1].vocabulary.key

    assert_equal('Cats', @item.title)
  end

  test 'update_from_xml should auto-normalize lat/long from date or dateCreated
  element' do
    xml = '<?xml version="1.0" encoding="utf-8"?>'
    xml += '<dls:Object xmlns:dls="http://digital.library.illinois.edu/terms#">'
    xml += '<dls:repositoryId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:repositoryId>'
    xml += '<dls:published>true</dls:published>'
    xml += '<dls:date vocabularyKey="uncontrolled" dataType="string">1964</dls:date>'
    xml += '</dls:Object>'

    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'

    @item.update_from_xml(doc, 3)
    assert_equal 1964, @item.date.year
  end

  test 'update_from_xml should auto-normalize lat/long from coordinates element
  when latitude and longitude elements are empty' do
    xml = '<?xml version="1.0" encoding="utf-8"?>'
    xml += '<dls:Object xmlns:dls="http://digital.library.illinois.edu/terms#">'
    xml += '<dls:repositoryId>e12adef0-5ca8-0132-3334-0050569601ca-8</dls:repositoryId>'
    xml += '<dls:published>true</dls:published>'
    xml += '<dls:coordinates vocabularyKey="uncontrolled" dataType="string">W 90⁰26\'05"/ N 40⁰39\'51"</dls:coordinates>'
    xml += '</dls:Object>'

    doc = Nokogiri::XML(xml, &:noblanks)
    doc.encoding = 'utf-8'

    @item.update_from_xml(doc, 3)
    assert_equal 39.25243, @item.latitude.to_f
    assert_equal -152.23423, @item.longitude.to_f
  end

end
