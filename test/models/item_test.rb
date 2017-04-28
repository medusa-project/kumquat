require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    @item = items(:sanborn_obj1_page1)
    assert @item.valid?
  end

  # Item.num_free_form_files()

  test 'num_free_form_files should return a correct count' do
    Item.all.each { |it| it.index_in_solr }
    Solr.instance.commit
    assert_equal 2, Item.num_free_form_files
  end

  # Item.num_free_form_items()

  test 'num_free_form_items should return a correct count' do
    Item.all.each { |it| it.index_in_solr }
    Solr.instance.commit
    assert_equal 3, Item.num_free_form_items
  end

  # Item.tsv_header()

  test 'tsv_header should return the correct columns' do
    expected = %w(uuid parentId preservationMasterPathname
    preservationMasterFilename preservationMasterUUID accessMasterPathname
    accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
    latitude longitude contentdmAlias contentdmPointer IGNORE Title Coordinates
    Creator Date\ Created Description lcsh:Subject tgm:Subject)
    cols = Item.tsv_header(@item.collection.metadata_profile).
        strip.split("\t")
    assert_equal expected, cols
  end

  test 'tsv_header should end with a line break' do
    assert Item.tsv_header(@item.collection.metadata_profile).
        end_with?(Item::TSV_LINE_BREAK)
  end

  # all_files()

  test 'all_files() should return the correct items' do
    assert_equal 1, items(:illini_union_dir1).all_files.count
  end

  # as_json()

  test 'as_json() should return the correct structure' do
    struct = @item.as_json
    assert_equal @item.repository_id, struct['repository_id']
    # We'll trust that all the other properties are present.
    assert_equal 2, struct['binaries'].length
    assert_equal 3, struct['elements'].length
  end

  # bib_id()

  test 'bib_id() should return the bibId element value, or nil if none exists' do
    assert_nil @item.bib_id

    @item.elements.build(name: 'bibId', value: 'cats')
    assert_equal 'cats', @item.bib_id
  end

  # catalog_record_url()

  test 'catalog_record_url() should return nil when bib_id() returns nil' do
    @item.elements.where(name: 'bibId').destroy_all
    assert_nil @item.catalog_record_url
  end

  test 'catalog_record_url() should return the catalog record URL when bib_id()
  returns a string' do
    @item.elements.build(name: 'bibId', value: '12345')
    assert_equal 'http://vufind.carli.illinois.edu/vf-uiu/Record/uiu_12345',
                 @item.catalog_record_url
  end

  # collection_repository_id

  test 'collection_repository_id must be a UUID' do
    @item.collection_repository_id = 123
    assert !@item.valid?

    @item.collection_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # composite_item()

  test 'composite_item() should return the composite item, or nil if none
  exists' do
    assert_nil @item.composite_item

    id = SecureRandom.uuid
    Item.create!(repository_id: id,
                 collection_repository_id: @item.collection_repository_id,
                 parent_repository_id: @item.repository_id,
                 variant: Item::Variants::COMPOSITE)
    assert_equal id, @item.composite_item.repository_id
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
    @item = items(:sanborn_obj1)
    @item.representative_item_repository_id = nil
    assert_equal 'd29950d0-c451-0133-1d17-0050569601ca-2',
                 @item.effective_representative_item.repository_id
  end

  test 'effective_representative_item should return the instance when
        representative_item_repository_id is not set and it has no pages' do
    @item = items(:sanborn_obj1)
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
    @item.elements.destroy_all
    assert_equal @item.collection.rights_statement,
                 @item.effective_rights_statement
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

  # repository_id

  test 'repository_id must be a UUID' do
    @item.repository_id = 123
    assert !@item.valid?

    @item.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # representative_item()

  test 'representative_item() should return nil when
  representative_item_repository_id is nil' do
    assert_nil(@item.representative_item)
  end

  test 'representative_item() should return nil when
  representative_item_repository_id is invalid' do
    @item.representative_item_repository_id = 'bogus'
    assert_nil(@item.representative_item)
  end

  test 'representative_item() should return an item when
  representative_item_repository_id is valid' do
    @item.representative_item_repository_id =
        items(:illini_union_dir1_file1).repository_id
    assert_kind_of Item, @item.representative_item
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
    item = items(:sanborn_obj1_page1)

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
    item = items(:sanborn_obj1_page1)

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
    item = items(:sanborn_obj1_page1)

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
    item = items(:sanborn_obj1_page1)
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

  test 'save() should set normalized coordinates if latitude and longitude are
  blank' do
    @item.latitude = nil
    @item.longitude = nil
    @item.element(:coordinates)&.destroy!
    @item.elements.build(name: 'coordinates',
                         value: 'W 90⁰26\'05"/ N 40⁰39\'51"')
    @item.save!
    assert_in_delta 40.664, @item.latitude.to_f, 0.001
    assert_in_delta -90.434, @item.longitude.to_f, 0.001
  end

  test 'save() should not overwrite latitude/longitude if either are present' do
    initial_lat = 54.24234
    initial_long = -123.234
    @item.latitude = initial_lat
    @item.longitude = initial_long
    @item.elements.build(name: 'coordinates',
                         value: 'W 90⁰26\'05"/ N 40⁰39\'51"')
    @item.save!
    assert_equal initial_lat, @item.latitude
    assert_equal initial_long, @item.longitude
  end

  test 'save() should set a normalized date, if blank, from a date element' do
    @item.date = nil
    @item.element(:date)&.destroy!
    @item.element(:dateCreated)&.destroy!
    @item.elements.build(name: 'date', value: '2010-01-02')
    @item.save!
    assert_equal Time.parse('2010-01-02').year, @item.date.year
  end

  test 'save() should not overwrite the normalized date if present' do
    initial_date = Time.now
    @item.date = Time.now
    @item.elements.build(name: 'date', value: '2010-01-02')
    @item.save!
    assert_equal initial_date.year, @item.date.year
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

  # supplementary_item()

  test 'supplementary_item() should return the supplementary item, or nil if
  none exists' do
    assert_nil @item.supplementary_item

    Item.create!(repository_id: SecureRandom.uuid,
                 collection_repository_id: @item.collection_repository_id,
                 parent_repository_id: @item.repository_id,
                 variant: Item::Variants::SUPPLEMENT)
    assert_equal Item::Variants::SUPPLEMENT, @item.supplementary_item.variant
  end

  # three_d_item()

  test 'three_d_item() should return the 3D model item, or nil if none exists' do
    assert_nil @item.three_d_item

    subitem = Item.new(repository_id: SecureRandom.uuid,
                       collection_repository_id: @item.collection_repository_id,
                       parent_repository_id: @item.repository_id)
    subitem.binaries.build(media_category: Binary::MediaCategory::THREE_D)
    subitem.save!

    assert_equal subitem, @item.three_d_item
  end

  # title()

  test 'title() should return the repository ID if no title element value
  exists' do
    @item.elements.destroy_all
    @item.save
    assert_equal @item.repository_id, @item.title
  end

  test 'title() should return the title element value if it exists' do
    assert_equal 'My Great Title', @item.title
  end

  # to_solr

  test 'to_solr should work' do
    doc = @item.to_solr

    assert_equal @item.solr_id, doc[Item::SolrFields::ID]
    assert_equal @item.class.to_s, doc[Item::SolrFields::CLASS]
    assert_equal @item.collection_repository_id,
                 doc[Item::SolrFields::COLLECTION]
    assert_equal "#{@item.parent_repository_id}-Page-1-ZZZZZZ-#{@item.title}",
                 doc[Item::SolrFields::GROUPED_SORT]
    assert doc[Item::SolrFields::COLLECTION_PUBLISHED]
    assert_equal @item.date.utc.iso8601, doc[Item::SolrFields::DATE]
    assert doc[Item::SolrFields::DESCRIBED]
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
    assert_equal @item.primary_media_category,
                 doc[Item::SolrFields::PRIMARY_MEDIA_CATEGORY]
    assert_equal @item.published, doc[Item::SolrFields::PUBLISHED]
    assert_equal @item.representative_item_repository_id,
                 doc[Item::SolrFields::REPRESENTATIVE_ITEM_ID]
    assert_equal @item.subpage_number, doc[Item::SolrFields::SUBPAGE_NUMBER]
    assert_equal @item.title, doc[Item::SolrFields::TITLE]
    assert_equal @item.binaries.map(&:byte_size).sum,
                 doc[Item::SolrFields::TOTAL_BYTE_SIZE]
    assert_equal @item.variant, doc[Item::SolrFields::VARIANT]

    title = @item.elements.select{ |e| e.name == 'title' }.first
    assert_equal [title.value], doc[title.solr_multi_valued_field]
    description = @item.elements.select{ |e| e.name == 'description' }.first
    assert_equal [description.value], doc[description.solr_multi_valued_field]
  end

  # update_from_embedded_metadata

  test 'update_from_embedded_metadata should work' do
    @item = items(:illini_union_dir1_file1)
    @item.update_from_embedded_metadata(include_date_created: true)

    assert_equal 1, @item.elements.
        select{ |e| e.name == 'title' and e.value == 'Illini Union Photographs Record Series 3707005' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'creator' and e.value == 'University of Illinois Library' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'dateCreated' and e.value == '2012-10-10' }.length
    assert_equal '2015-08-10T05:00:00Z', @item.date.iso8601
  end

  # update_from_json

  test 'update_from_json should work' do
    struct = @item.as_json
    struct['contentdm_alias'] = 'cats'
    struct['contentdm_pointer'] = 99
    struct['date'] = '2014-03-01T16:25:15Z'
    struct['embed_tag'] = '<embed></embed>'
    struct['full_text'] = 'Some full text'
    struct['latitude'] = 23.45
    struct['longitude'] = -34.56
    struct['page_number'] = 60
    struct['published'] = true
    struct['representative_item_repository_id'] =
        'd29950d0-c451-0133-1d17-0050569601ca-2'
    struct['subpage_number'] = 61
    struct['variant'] = Item::Variants::PAGE
    desc = struct['elements'].select{ |e| e['name'] == 'description' }.first
    desc['string'] = 'Something'
    desc['uri'] = 'http://example.org/something'

    json = JSON.generate(struct)

    @item.update_from_json(json)

    assert_equal 'cats', @item.contentdm_alias
    assert_equal 99, @item.contentdm_pointer
    assert_equal 2014, @item.date.year
    assert_equal 'Some full text', @item.full_text
    assert_equal 23.45, @item.latitude
    assert_equal -34.56, @item.longitude
    assert_equal 60, @item.page_number
    assert @item.published
    assert_equal 'd29950d0-c451-0133-1d17-0050569601ca-2',
                 @item.representative_item_repository_id
    assert_equal 61, @item.subpage_number
    assert_equal Item::Variants::PAGE, @item.variant

    assert_equal 3, @item.elements.length
    description = @item.elements.select{ |e| e.name == 'description' }.first
    assert_equal 'Something', description.value
    assert_equal 'http://example.org/something', description.uri
    assert_equal 'uncontrolled', description.vocabulary.key
  end

  test 'update_from_json should raise an error with invalid data' do
    struct = @item.as_json
    struct['latitude'] = 130.234

    json = JSON.generate(struct)

    assert_raises ActiveRecord::RecordInvalid do
      @item.update_from_json(json)
    end
  end

  # update_from_tsv

  test 'update_from_tsv should work' do
    row = {}
    # technical elements
    row['contentdmAlias'] = 'cats'
    row['contentdmPointer'] = '123'
    row['latitude'] = '45.52'
    row['longitude'] = '-120.564'
    row['pageNumber'] = '3'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE

    # descriptive elements
    row['Description'] = 'Cats' +
        Item::TSV_MULTI_VALUE_SEPARATOR +
        'cats' + Item::TSV_URI_VALUE_SEPARATOR + '<http://example.org/cats1>' +
        Item::TSV_MULTI_VALUE_SEPARATOR +
        'and more cats' + Item::TSV_URI_VALUE_SEPARATOR + '<http://example.org/cats2>'
    row['Title'] = 'Cats & Stuff'
    row['lcsh:Subject'] = 'Cats'

    @item.update_from_tsv(row)

    assert_equal 'cats', @item.contentdm_alias
    assert_equal 123, @item.contentdm_pointer
    assert_equal 45.52, @item.latitude
    assert_equal -120.564, @item.longitude
    assert_equal 3, @item.page_number
    assert_equal 1, @item.subpage_number
    assert_equal Item::Variants::PAGE, @item.variant

    assert_equal 5, @item.elements.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'title' and
        e.value == 'Cats & Stuff' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'description' and
        e.value == 'cats' and e.uri == 'http://example.org/cats1' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'description' and
        e.value == 'and more cats' and e.uri == 'http://example.org/cats2' }.length
    assert_equal 1, @item.elements.select{ |e| e.name == 'subject' and
        e.value == 'Cats' and e.vocabulary == vocabularies(:lcsh) }.length
  end

  test 'update_from_tsv should raise an error if given an invalid element name' do
    row = {}
    row['Title'] = 'Cats'
    row['TotallyBogus'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

  test 'update_from_tsv should raise an error if given an invalid vocabulary prefix' do
    row = {}
    row['Title'] = 'Cats'
    row['bogus:Subject'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

end
