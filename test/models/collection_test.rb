require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:sanborn)
    assert @collection.valid?
  end

  # from_medusa()

  test 'from_medusa with an invalid ID should raise an error' do
    assert_raises ActiveRecord::RecordNotFound do
      Collection.from_medusa('cats')
    end
  end

  test 'from_medusa should work' do
    uuid = @collection.repository_id
    @collection.destroy!

    @collection = Collection.from_medusa(uuid)
    assert_equal 'Sanborn Fire Insurance Maps', @collection.title
  end

  # change_item_element_values()

  test 'change_item_element_values() should work' do
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tiger')
    item.elements.build(name: 'cat', value: 'leopard')
    item.save!

    @collection.change_item_element_values('cat', [
        { string: 'lion', uri: 'http://example.org/lion' },
        { string: 'cougar', uri: 'http://example.org/cougar' }
    ])

    item.reload
    assert_equal 2, item.elements.select{ |e| e.name == 'cat' }.length
    elements = item.elements.select{ |e| e.name == 'cat' }
    assert elements.map(&:value).include?('lion')
    assert elements.map(&:uri).include?('http://example.org/lion')
    assert elements.map(&:value).include?('cougar')
    assert elements.map(&:uri).include?('http://example.org/cougar')
  end

  # effective_metadata_profile()

  test 'effective_metadata_profile() should return the assigned metadata
  profile' do
    assert_equal @collection.metadata_profile, @collection.effective_metadata_profile
  end

  test 'effective_metadata_profile() should return the default metadata
  profile if not assigned' do
    @collection.metadata_profile = nil
    assert_equal MetadataProfile.default, @collection.effective_metadata_profile
  end

  # items()

  test 'items should return all items' do
    assert_equal 4, @collection.items.length
  end

  # items_as_tsv()

  test 'items_as_tsv should work' do
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
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
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
    assert_equal to_tsv(expected_header, expected_values), @collection.items_as_tsv
  end

  test 'items_as_tsv should work with the only_undescribed: true option' do
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
            'uuid': 'd29edba0-c451-0133-1d17-0050569601ca-c',
            'parentId': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'preservationMasterUUID': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'accessMasterUUID': nil,
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
    assert_equal to_tsv(expected_header, expected_values),
                 @collection.items_as_tsv(only_undescribed: true)
  end

  # medusa_cfs_directory()

  test 'medusa_cfs_directory() should return nil if medusa_cfs_directory_id is
  nil' do
    @collection.medusa_cfs_directory_id = nil
    assert_nil @collection.medusa_cfs_directory
  end

  test 'medusa_cfs_directory() should return a MedusaCfsDirectory when
  medusa_cfs_directory_id is set' do
    @collection.medusa_cfs_directory_id = 'be8d3500-c451-0133-1d17-0050569601ca-9'
    assert_equal @collection.medusa_cfs_directory.uuid,
                 @collection.medusa_cfs_directory_id
  end

  # medusa_cfs_directory_id

  test 'medusa_cfs_directory_id must be a valid Medusa directory ID' do
    # set it to a file group UUID
    @collection.medusa_cfs_directory_id = '7afc3e80-b41b-0134-234d-0050569601ca-7'
    assert !@collection.valid?
    # set it to a file UUID
    @collection.medusa_cfs_directory_id = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@collection.valid?
  end

  # medusa_file_group()

  test 'medusa_file_group() should return nil if medusa_file_group_id is nil' do
    @collection.medusa_file_group_id = nil
    assert_nil @collection.medusa_file_group
  end

  test 'medusa_file_group() should return a MedusaFileGroup' do
    assert_equal @collection.medusa_file_group.uuid, @collection.medusa_file_group_id
  end

  # meduse_file_group_id

  test 'medusa_file_group_id must be a valid Medusa file group ID' do
    # set it to a directory UUID
    @collection.medusa_file_group_id = '7b1f3340-b41b-0134-234d-0050569601ca-8'
    assert !@collection.valid?
    # set it to a file UUID
    @collection.medusa_file_group_id = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@collection.valid?
  end

  # medusa_repository()

  test 'medusa_repository() should return nil if medusa_repository_id is nil' do
    @collection.medusa_repository_id = nil
    assert_nil @collection.medusa_repository
  end

  test 'medusa_repository() should return a MedusaRepository' do
    assert_equal @collection.medusa_repository.id, @collection.medusa_repository_id
  end

  # medusa_url()

  test 'medusa_url() should return nil when the repository ID is nil' do
    @collection.repository_id = nil
    assert_nil @collection.medusa_url
  end

  # medusa_url()

  test 'medusa_url should return the correct URL' do
    # without format
    expected = sprintf('%s/uuids/%s',
                       Configuration.instance.medusa_url.chomp('/'),
                       @collection.repository_id)
    assert_equal(expected, @collection.medusa_url)

    # with format
    expected = sprintf('%s/uuids/%s.json',
                       Configuration.instance.medusa_url.chomp('/'),
                       @collection.repository_id)
    assert_equal(expected, @collection.medusa_url('json'))
  end

  # migrate_item_elements()

  test 'migrate_item_elements() should raise an error when given a destination
  element that is not present in the metadata profile' do
    assert_raises ArgumentError do
      @collection.migrate_item_elements('title', 'bogus')
    end
  end

  test 'migrate_item_elements() should raise an error when source and
  destination elements have different vocabularies' do
    assert_raises ArgumentError do
      @collection.migrate_item_elements('title', 'subject')
    end
  end

  test 'migrate_item_elements() should work' do
    test_item = items(:sanborn_obj1_page1)
    test_title = test_item.title
    assert_not_empty test_title
    assert_equal 1, test_item.elements.select{ |e| e.name == 'description' }.length

    @collection.migrate_item_elements('title', 'description')

    test_item.reload
    assert_empty test_item.elements.select{ |e| e.name == 'title' }
    assert_equal 2, test_item.elements.select{ |e| e.name == 'description' }.length
  end

  # package_profile()

  test 'package_profile should return a PackageProfile' do
    assert @collection.package_profile.kind_of?(PackageProfile)
    @collection.package_profile_id = 37
    assert_nil @collection.package_profile
  end

  # package_profile=()

  test 'package_profile= should set a PackageProfile' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_equal @collection.package_profile_id, PackageProfile::COMPOUND_OBJECT_PROFILE.id
  end

  # purge()

  test 'purge() should purge all items' do
    assert @collection.items.count > 0
    @collection.purge
    assert @collection.items.count == 0
  end

  # replace_item_element_values()

  test 'replace_item_element_values() should work with :exact_match matching
  mode and :whole_value replace mode' do
    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @collection.replace_item_element_values(:exact_match, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @collection.replace_item_element_values(:exact_match, 'foxes', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'tigers', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :exact_match matching
  mode and :matched_part replace mode' do
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @collection.replace_item_element_values(:exact_match, 'ZZZtigersZZZ', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :contain matching mode
  and :whole_value replace mode' do
    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @collection.replace_item_element_values(:contain, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'foxes')
    item.save!

    @collection.replace_item_element_values(:contain, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'foxes', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :contain matching mode
  and :matched_part replace mode' do
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @collection.replace_item_element_values(:contain, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlionsZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :start matching mode and
  :whole_value replace mode' do
    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @collection.replace_item_element_values(:start, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @collection.replace_item_element_values(:start, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'ZZZtigers', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :start matching mode and
  :matched_part replace mode' do
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @collection.replace_item_element_values(:start, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lionsZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :end matching mode and
  :whole_value replace mode' do
    # Test match
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @collection.replace_item_element_values(:end, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @collection.replace_item_element_values(:end, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'tigersZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with end matching mode and
  matched_part replace mode' do
    item = items(:sanborn_obj1_page1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @collection.replace_item_element_values(:end, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlions', item.element(:cat).value
  end

  # repository_id

  test 'repository_id must be a UUID' do
    @collection.repository_id = 123
    assert !@collection.valid?

    @collection.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @collection.valid?
  end

  # solr_id()

  test 'solr_id should return the repository ID' do
    assert_equal @collection.repository_id, @collection.solr_id
  end

  # to_param()

  test 'to_param should return the repository ID' do
    assert_equal @collection.repository_id, @collection.to_param
  end

  # to_s()

  test 'to_s should return the title element value if available' do
    title = 'My Great Title'
    @collection.elements.build(name: 'title', value: title)
    @collection.save!
    assert_equal title, @collection.title
  end

  test 'to_s should return the repository ID if there is no title element' do
    assert_equal '6ff64b00-072d-0130-c5bb-0019b9e633c5-2', @collection.title
  end

  # to_solr()

  test 'to_solr return the correct Solr document' do
    doc = @collection.to_solr

    assert_equal @collection.solr_id, doc[Collection::SolrFields::ID]
    assert_equal @collection.class.to_s, doc[Collection::SolrFields::CLASS]
    assert_not_empty doc[Collection::SolrFields::LAST_INDEXED]
    assert_equal @collection.access_systems, doc[Collection::SolrFields::ACCESS_SYSTEMS]
    assert_equal @collection.access_url, doc[Collection::SolrFields::ACCESS_URL]
    assert_equal @collection.allowed_roles.map(&:key).sort,
                 doc[Collection::SolrFields::ALLOWED_ROLES].sort
    assert_equal @collection.denied_roles.map(&:key).sort,
                 doc[Collection::SolrFields::DENIED_ROLES].sort
    assert_equal @collection.description, doc[Collection::SolrFields::DESCRIPTION]
    assert_equal @collection.description_html, doc[Collection::SolrFields::DESCRIPTION_HTML]
    assert_equal @collection.external_id, doc[Collection::SolrFields::EXTERNAL_ID]
    assert_equal @collection.harvestable, doc[Collection::SolrFields::HARVESTABLE]
    assert_equal @collection.description, doc[Collection::SolrFields::METADATA_DESCRIPTION]
    assert_equal @collection.title, doc[Collection::SolrFields::METADATA_TITLE]
    assert_equal @collection.published, doc[Collection::SolrFields::PUBLISHED]
    assert_empty doc[Collection::SolrFields::PARENT_COLLECTIONS]
    assert_equal @collection.published_in_dls,
                 doc[Collection::SolrFields::PUBLISHED_IN_DLS]
    assert_equal @collection.medusa_repository.title,
                 doc[Collection::SolrFields::REPOSITORY_TITLE]
    assert_equal @collection.representative_item_id,
                 doc[Collection::SolrFields::REPRESENTATIVE_ITEM]
    assert_equal @collection.resource_types, doc[Collection::SolrFields::RESOURCE_TYPES]
    assert_equal @collection.title, doc[Collection::SolrFields::TITLE]
  end

  # update_from_medusa()

  test 'update_from_medusa should raise an error if the repository ID is invalid' do
    c = Collection.new
    # Not set
    assert_raises ActiveRecord::RecordNotFound do
      c.update_from_medusa
    end

    # Set incorrectly
    c.repository_id = 'bogus'
    assert_raises ActiveRecord::RecordNotFound do
      c.update_from_medusa
    end
  end

  test 'update_from_medusa should work' do
    uuid = '6ff64b00-072d-0130-c5bb-0019b9e633c5-2'
    Collection.find_by_repository_id(uuid)&.destroy!

    c = Collection.new(repository_id: uuid)
    c.update_from_medusa

    assert_equal 'Sanborn Fire Insurance Maps', c.title
  end

  private

  ##
  # @param header [Array]
  # @param values [Array<Hash<String,Object>>]
  # @return [String]
  #
  def to_tsv(header, values)
    header.join("\t") + Item::TSV_LINE_BREAK +
        values.map { |v| v.values.join("\t") }.join(Item::TSV_LINE_BREAK) +
        Item::TSV_LINE_BREAK
  end

end
