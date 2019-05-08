require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  setup do
    @item = items(:sanborn_obj1_page1)
    assert @item.valid?

    ElasticsearchIndex.migrate_to_latest
    ElasticsearchClient.instance.recreate_all_indexes rescue nil
  end

  # Item.num_free_form_files()

  test 'num_free_form_files() should return a correct count' do
    Item.all.each(&:reindex)
    sleep 2
    assert_equal Item.where(variant: Item::Variants::FILE).count,
                 Item.num_free_form_files
  end

  # Item.num_free_form_items()

  test 'num_free_form_items() should return a correct count' do
    Item.all.each(&:reindex)
    sleep 2
    assert_equal Item.where(variant: [Item::Variants::FILE, Item::Variants::DIRECTORY]).count,
                 Item.num_free_form_items
  end

  # Item.num_objects()

  test 'num_objects() should return a correct count' do
    Item.all.each(&:reindex)
    sleep 2
    assert_equal Item.where('variant = ? OR variant IS NULL',
                            Item::Variants::FILE).count,
                 Item.num_objects
  end

  # Item.tsv_columns()

  test 'tsv_columns() should return the correct columns' do
    expected = %w(uuid parentId preservationMasterPathname
    preservationMasterFilename preservationMasterUUID accessMasterPathname
    accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
    contentdmAlias contentdmPointer IGNORE Title Coordinates
    Creator Date\ Created Description lcsh:Subject tgm:Subject)
    actual = Item.tsv_columns(@item.collection.metadata_profile)
    assert_equal expected, actual
  end

  # all_children()

  test 'all_children() should return the correct items' do
    assert_equal items(:sanborn_obj1).items.count,
                 items(:sanborn_obj1).all_children.count
  end

  # all_files()

  test 'all_files() should return the correct items' do
    assert_equal 1, items(:illini_union_dir1_dir1).all_files.count
  end

  # all_parents()

  test 'all_parents() should return the parents' do
    result = items(:illini_union_dir1_dir1_file1).all_parents
    assert_equal 2, result.count
    assert_equal items(:illini_union_dir1_dir1).repository_id,
                 result[0].repository_id
    assert_equal items(:illini_union_dir1).repository_id,
                 result[1].repository_id
  end

  # as_indexed_json()

  test 'as_indexed_json returns the correct structure' do
    doc = @item.as_indexed_json

    assert_equal @item.collection_repository_id,
                 doc[Item::IndexFields::COLLECTION]
    assert_equal @item.date.utc.iso8601,
                 doc[Item::IndexFields::DATE]
    assert_equal @item.described?,
                 doc[Item::IndexFields::DESCRIBED]
    assert_equal @item.effective_allowed_roles.pluck(:key),
                 doc[Item::IndexFields::EFFECTIVE_ALLOWED_ROLES]
    assert_equal @item.effective_allowed_roles.pluck(:key).length,
                 doc[Item::IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT]
    assert_equal @item.effective_denied_roles.pluck(:key),
                 doc[Item::IndexFields::EFFECTIVE_DENIED_ROLES]
    assert_equal @item.effective_denied_roles.pluck(:key).length,
                 doc[Item::IndexFields::EFFECTIVE_DENIED_ROLE_COUNT]
    assert_equal @item.item_sets.pluck(:id),
                 doc[Item::IndexFields::ITEM_SETS]
    assert_not_empty doc[Item::IndexFields::LAST_INDEXED]
    assert_equal @item.updated_at.utc.iso8601,
                 doc[Item::IndexFields::LAST_MODIFIED]
    assert_equal({ lat: @item.latitude, lon: @item.longitude },
                 doc[Item::IndexFields::LAT_LONG])
    assert_equal(@item.parent.repository_id,
                 doc[Item::IndexFields::OBJECT_REPOSITORY_ID])
    assert_equal @item.page_number,
                 doc[Item::IndexFields::PAGE_NUMBER]
    assert_equal @item.parent_repository_id,
                 doc[Item::IndexFields::PARENT_ITEM]
    assert_equal @item.primary_media_category,
                 doc[Item::IndexFields::PRIMARY_MEDIA_CATEGORY]
    assert doc[Item::IndexFields::PUBLICLY_ACCESSIBLE]
    assert_equal @item.published,
                 doc[Item::IndexFields::PUBLISHED]
    assert_equal @item.repository_id,
                 doc[Item::IndexFields::REPOSITORY_ID]
    assert_equal @item.representative_filename,
                 doc[Item::IndexFields::REPRESENTATIVE_FILENAME]
    assert_equal @item.representative_item_repository_id,
                 doc[Item::IndexFields::REPRESENTATIVE_ITEM]
    assert_equal "#{@item.parent_repository_id}-iaa-0000000000000001-zzz-#{@item.title.downcase}",
                 doc[Item::IndexFields::STRUCTURAL_SORT]
    assert_equal @item.subpage_number,
                 doc[Item::IndexFields::SUBPAGE_NUMBER]
    assert_equal @item.binaries.pluck(:byte_size).sum,
                 doc[Item::IndexFields::TOTAL_BYTE_SIZE]
    assert_equal @item.variant,
                 doc[Item::IndexFields::VARIANT]

    title = @item.element(:title)
    assert_equal [title.value], doc[title.indexed_field]
    description = @item.element(:description)
    assert_equal [description.value], doc[description.indexed_field]
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
    @item.save!
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
    @item.save!
    assert_equal 'http://vufind.carli.illinois.edu/vf-uiu/Record/uiu_12345/Description',
                 @item.catalog_record_url
  end

  # collection_repository_id

  test 'collection_repository_id must be a UUID' do
    @item.collection_repository_id = 123
    assert !@item.valid?

    @item.collection_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # described?()

  test 'described?() returns true when the item is in a free-form collection
  and has a title element' do
    @item.collection = collections(:illini_union)
    @item.elements.destroy_all
    @item.elements.build(name: 'title', value: 'cats')
    assert @item.described?
  end

  test 'described?() returns true when the item is in a free-form collection
  and has directory variant' do
    @item.collection = collections(:illini_union)
    @item.elements.destroy_all
    @item.variant = Item::Variants::DIRECTORY
    assert @item.described?
  end

  test 'described?() returns false when the item is in a free-form collection,
  has no title element, and is not directory-variant' do
    @item.collection = collections(:illini_union)
    @item.elements.destroy_all
    @item.variant = nil
    assert !@item.described?
  end

  test 'described?() returns true when the item is in a non-free-form collection
  and has an element other than title' do
    @item.elements.destroy_all
    @item.elements.build(name: 'subject', value: 'cats')
    assert @item.described?
  end

  test 'described?() returns false when the item is in a non-free-form collection
  and does not have a title element' do
    @item.elements.destroy_all
    assert !@item.described?
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

  # directory?()

  test 'directory?() returns the correct value' do
    @item.variant = nil
    assert !@item.directory?

    @item.variant = Item::Variants::FILE
    assert !@item.directory?

    @item.variant = Item::Variants::DIRECTORY
    assert @item.directory?
  end

  # effective_representative_entity()

  test 'effective_representative_entity should return the representative item
        when it is assigned' do
    id = 'a53add10-5ca8-0132-3334-0050569601ca-7'
    @item.representative_item_repository_id = id
    assert_equal id, @item.effective_representative_entity.repository_id
  end

  test 'effective_representative_entity should return the first page when
        representative_item_repository_id is not set' do
    @item = items(:sanborn_obj1)
    @item.representative_item_repository_id = nil
    assert_equal 'd29950d0-c451-0133-1d17-0050569601ca-2',
                 @item.effective_representative_entity.repository_id
  end

  test 'effective_representative_entity should return the instance when
        representative_item_repository_id is not set and it has no pages' do
    @item = items(:sanborn_obj1)
    @item.representative_item_repository_id = nil
    @item.items.delete_all
    assert_equal @item.repository_id,
                 @item.effective_representative_entity.repository_id
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

  # file?()

  test 'file?() returns the correct value' do
    @item.variant = nil
    assert !@item.file?

    @item.variant = Item::Variants::DIRECTORY

    assert !@item.file?

    @item.variant = Item::Variants::FILE
    assert @item.file?
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

  # propagate_heritable_properties()

  test 'propagate_heritable_properties() should propagate roles to children' do
    # Clear all roles on the item and its children.
    @item.allowed_roles.destroy_all
    @item.denied_roles.destroy_all
    @item.save!

    @item.items.each do |it|
      it.allowed_roles.destroy_all
      it.denied_roles.destroy_all
      it.save!

      assert_equal 0, it.effective_allowed_roles.count
      assert_equal 0, it.effective_denied_roles.count
    end

    # Add roles to the item.
    @item.allowed_roles << roles(:admins)
    @item.denied_roles << roles(:catalogers)

    # Propagate heritable properties.
    @item.propagate_heritable_properties

    # Assert that the item's children have inherited the roles.
    @item.items.each do |it|
      assert_equal 1, it.effective_allowed_roles.count
      assert it.effective_allowed_roles.include?(roles(:admins))

      assert_equal 1, it.effective_denied_roles.count
      assert it.effective_denied_roles.include?(roles(:catalogers))
    end
  end

  # publicly_accessible?()

  test 'publicly_accessible?() should return true when the instance and its
  collection are both published' do
    @item.published = true
    @item.collection.published_in_dls = true
    assert @item.publicly_accessible?
  end

  test 'publicly_accessible?() should return false when the instance is
  published but its collection is not' do
    @item.published = true
    @item.collection.published_in_dls = false
    assert !@item.publicly_accessible?
  end

  test 'publicly_accessible?() should return false when the instance is not
  published but its collection is' do
    @item.published = false
    @item.collection.published_in_dls = true
    assert !@item.publicly_accessible?
  end

  test 'publicly_accessible?() should return false when neither the instance
  nor its collection are published' do
    @item.published = false
    @item.collection.published_in_dls = false
    assert !@item.publicly_accessible?
  end

  # repository_id

  test 'repository_id must be a UUID' do
    @item.repository_id = 123
    assert !@item.valid?

    @item.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # representative_filename()

  test 'representative_filename() should return the representative filename' do
    assert_equal '1601831_001', @item.representative_filename
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
        items(:illini_union_dir1_dir1_file1).repository_id
    assert_kind_of Item, @item.representative_item
  end

  # representative_item_repository_id

  test 'representative_item_repository_id must be a UUID' do
    @item.representative_item_repository_id = 123
    assert !@item.valid?

    @item.representative_item_repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @item.valid?
  end

  # root_parent()

  test 'root_parent returns the root parent, if available' do
    @item = items(:illini_union_dir1_dir1_file1)
    assert_equal items(:illini_union_dir1).repository_id,
                 @item.root_parent.repository_id
  end

  test 'root_parent returns the instance if it has no parents' do
    @item = items(:sanborn_obj1)
    assert_same @item, @item.root_parent
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
    item.allowed_roles << roles(:students)
    item.denied_roles.destroy_all
    item.denied_roles << roles(:catalogers)
    # Assert that they get propagated to effective roles.
    item.save!
    assert_equal 1, item.effective_allowed_roles.length
    assert_equal 'students', item.effective_allowed_roles.first.key
    assert_equal 1, item.effective_denied_roles.length
    assert_equal 'catalogers', item.effective_denied_roles.first.key
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

  test 'save() should set normalized coordinates' do
    @item.element(:coordinates)&.destroy!
    @item.elements.build(name: 'coordinates',
                         value: 'W 90⁰26\'05"/ N 40⁰39\'51"')
    @item.save!
    assert_in_delta 40.664, @item.latitude.to_f, 0.001
    assert_in_delta -90.434, @item.longitude.to_f, 0.001
  end

  test 'save() should set a normalized date from a date element' do
    @item.element(:date)&.destroy!
    @item.element(:dateCreated)&.destroy!
    @item.elements.build(name: 'date', value: '2010-01-02')
    @item.elements.build(name: 'dateCreated', value: '1995-01-02')
    @item.save!
    assert_equal Time.parse('2010-01-02').year, @item.date.year
  end

  test 'save() should set a normalized date from a dateCreated element if there
  is no date element' do
    @item.element(:date)&.destroy!
    @item.element(:dateCreated)&.destroy!
    @item.elements.build(name: 'dateCreated', value: '2010-01-02')
    @item.save!
    assert_equal Time.parse('2010-01-02').year, @item.date.year
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

  test 'three_d_item returns the 3D model item, or nil if none exists' do
    assert_nil @item.three_d_item

    subitem = Item.new(repository_id: SecureRandom.uuid,
                       collection_repository_id: @item.collection_repository_id,
                       parent_repository_id: @item.repository_id,
                       variant: Item::Variants::THREE_D_MODEL)
    subitem.binaries.build(media_category: Binary::MediaCategory::THREE_D,
                           object_key: 'bogus',
                           byte_size: 0)
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

  # update_from_embedded_metadata

  test 'update_from_embedded_metadata works' do
    @item = items(:illini_union_dir1_dir1_file1)
    @item.elements.destroy_all
    @item.update_from_embedded_metadata(include_date_created: true)

    assert_equal 1, @item.elements.
        select{ |e| e.name == 'title' and e.value == 'Illini Union Photographs Record Series 3707005' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'creator' and e.value == 'University of Illinois Library' }.length
    assert_equal 1, @item.elements.
        select{ |e| e.name == 'dateCreated' and e.value == '2012-10-10' }.length
    assert_equal '2012-10-10T05:00:00Z', @item.date.iso8601
  end

  # update_from_json

  test 'update_from_json() should work' do
    struct = @item.as_json
    struct['contentdm_alias'] = 'cats'
    struct['contentdm_pointer'] = 99
    struct['embed_tag'] = '<embed></embed>'
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
    struct['variant'] = 'bogus'

    json = JSON.generate(struct)

    assert_raises ActiveRecord::RecordInvalid do
      @item.update_from_json(json)
    end
  end

  # update_from_tsv

  test 'update_from_tsv() works' do
    row = {}
    # technical elements
    row['contentdmAlias'] = 'cats'
    row['contentdmPointer'] = '123'
    row['pageNumber'] = '3'
    row['subpageNumber'] = '1'
    row['variant'] = Item::Variants::PAGE

    # descriptive elements
    row['Description'] = 'Cats' +
        ItemTsvExporter::MULTI_VALUE_SEPARATOR +
        'cats' + ItemTsvExporter::URI_VALUE_SEPARATOR + '<http://example.org/cats1>' +
        ItemTsvExporter::MULTI_VALUE_SEPARATOR +
        'and more cats' + ItemTsvExporter::URI_VALUE_SEPARATOR + '<http://example.org/cats2>'
    row['Title'] = 'Cats & Stuff'
    row['lcsh:Subject'] = 'Cats'

    @item.update_from_tsv(row)

    assert_equal 'cats', @item.contentdm_alias
    assert_equal 123, @item.contentdm_pointer
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

  test 'update_from_tsv() raises an error when given an invalid element name' do
    row = {}
    row['Title'] = 'Cats'
    row['TotallyBogus'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

  test 'update_from_tsv() raises an error when given an invalid vocabulary prefix' do
    row = {}
    row['Title'] = 'Cats'
    row['bogus:Subject'] = 'Felines'

    assert_raises ArgumentError do
      @item.update_from_tsv(row)
    end
  end

  # virtual_filename()

  test 'virtual_filename() works properly' do
    assert_equal @item.binaries.select{ |b| b.master_type == Binary::MasterType::PRESERVATION }.first.filename,
                 @item.virtual_filename

    @item.binaries.destroy_all
    assert_nil @item.virtual_filename
  end

  # walk_tree()

  test 'walk_tree() should walk the tree' do
    count = 0
    @item = items(:sanborn_obj1)
    @item.walk_tree do |item|
      assert_kind_of(Item, item)
      count += 1
    end
    assert_equal count, @item.all_children.length
  end

end
