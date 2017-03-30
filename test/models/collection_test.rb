require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    @col = collections(:collection1)
    assert @col.valid?
  end

  # from_medusa()

  test 'from_medusa with an invalid ID should raise an error' do
    assert_raises ActiveRecord::RecordNotFound do
      Collection.from_medusa('cats')
    end
  end

  test 'from_medusa should work' do
    col = Collection.from_medusa('6ff64b00-072d-0130-c5bb-0019b9e633c5-2')
    assert_equal 'Sanborn Fire Insurance Maps', col.title
  end

  # change_item_element_values()

  test 'change_item_element_values() should work' do
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'tiger')
    item.elements.build(name: 'cat', value: 'leopard')
    item.save!

    @col.change_item_element_values('cat', [
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
    assert_equal @col.metadata_profile, @col.effective_metadata_profile
  end

  test 'effective_metadata_profile() should return the default metadata
  profile if not assigned' do
    @col.metadata_profile = nil
    assert_equal MetadataProfile.default, @col.effective_metadata_profile
  end

  # items()

  test 'items should return all items' do
    assert_equal 7, @col.items.length
  end

  # items_as_tsv()

  test 'items_as_tsv should work' do
    expected_header = [
        'uuid', 'parentId', 'preservationMasterPathname',
        'preservationMasterFilename', 'accessMasterPathname',
        'accessMasterFilename', 'variant', 'pageNumber', 'subpageNumber',
        'latitude', 'longitude', 'contentdmAlias', 'contentdmPointer',
        'IGNORE', 'Title', 'Coordinates', 'Creator', 'Date Created',
        'Description', 'lcsh:Subject', 'tgm:Subject'
    ]
    expected_values = [
        {
            'uuid': 'a1234567-5ca8-0132-3334-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': '/136/310/3707005/access/online/Illini_Union_Photographs/binder_9/memorial_stadium_assembly_hall/memorial_stadium_assembly_hall_020a.jpg',
            'preservationMasterFilename': 'memorial_stadium_assembly_hall_020a.jpg',
            'accessMasterPathname': '/136/310/3707005/access/online/Illini_Union_Photographs/binder_9/memorial_stadium_assembly_hall/memorial_stadium_assembly_hall_017b.jpg',
            'accessMasterFilename': 'memorial_stadium_assembly_hall_017b.jpg',
            'variant': nil,
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': '39.2524300',
            'longitude': '-152.2342300',
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '4',
            'Title': 'My Great Title',
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': 'About something',
            'lcsh:Subject': 'Cats&&<http://example.org/cats1>',
            'tgm:Subject': 'More cats&&<http://example.org/cats2>'
        },
        {
            'uuid': 'a53add10-5ca8-0132-3334-0050569601ca-7',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'variant': 'Directory',
            'pageNumber': nil,
            'subpageNumber': nil,
            'latitude': nil,
            'longitude': nil,
            'contentdmAlias': nil,
            'contentdmPointer': nil,
            'IGNORE': '1',
            'Title': nil,
            'Coordinates': nil,
            'Creator': nil,
            'Date Created': nil,
            'Description': nil,
            'lcsh:Subject': nil,
            'tgm:Subject': nil
        },
        {
            'uuid': '6e406030-5ce3-0132-3334-0050569601ca-3',
            'parentId': 'a53add10-5ca8-0132-3334-0050569601ca-7',
            'preservationMasterPathname': '/136/310/3707005/access/online/Illini_Union_Photographs/binder_9/memorial_stadium_assembly_hall/memorial_stadium_assembly_hall_015b.jpg',
            'preservationMasterFilename': 'memorial_stadium_assembly_hall_015b.jpg',
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'variant': 'File',
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
            'uuid': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
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
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'variant': 'Page',
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
            'preservationMasterPathname': 'MyString',
            'preservationMasterFilename': 'MyString',
            'accessMasterPathname': 'MyString',
            'accessMasterFilename': 'MyString',
            'variant': 'Page',
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
            'uuid': 'cd2d4601-c451-0133-1d17-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
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
    assert_equal to_tsv(expected_header, expected_values), @col.items_as_tsv
  end

  test 'items_as_tsv should work with the only_undescribed: true option' do
    item = @col.items.order(:repository_id).first
    item.elements.destroy_all
    item.elements.build(name: 'description', value: 'some new description')
    item.save

    # The gist of this test is that there should not be any IGNORE column
    # values > 0.

    expected_header = [
        'uuid', 'parentId', 'preservationMasterPathname',
        'preservationMasterFilename', 'accessMasterPathname',
        'accessMasterFilename', 'variant', 'pageNumber', 'subpageNumber',
        'latitude', 'longitude', 'contentdmAlias', 'contentdmPointer',
        'IGNORE', 'Title', 'Coordinates', 'Creator', 'Date Created',
        'Description', 'lcsh:Subject', 'tgm:Subject'
    ]
    expected_values = [
        {
            'uuid': 'be8d3500-c451-0133-1d17-0050569601ca-9',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
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
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
            'variant': 'Page',
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
            'preservationMasterPathname': 'MyString',
            'preservationMasterFilename': 'MyString',
            'accessMasterPathname': 'MyString',
            'accessMasterFilename': 'MyString',
            'variant': 'Page',
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
            'uuid': 'cd2d4601-c451-0133-1d17-0050569601ca-8',
            'parentId': nil,
            'preservationMasterPathname': nil,
            'preservationMasterFilename': nil,
            'accessMasterPathname': nil,
            'accessMasterFilename': nil,
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
                 @col.items_as_tsv(only_undescribed: true)
  end

  # medusa_cfs_directory()

  test 'medusa_cfs_directory() should return nil if medusa_cfs_directory_id is
  nil' do
    @col.medusa_cfs_directory_id = nil
    assert_nil @col.medusa_cfs_directory
  end

  test 'medusa_cfs_directory() should return a MedusaCfsDirectory' do
    assert_equal @col.medusa_cfs_directory.uuid, @col.medusa_cfs_directory_id
  end

  # medusa_cfs_directory_id

  test 'medusa_cfs_directory_id must be a valid Medusa directory ID' do
    # set it to a file group UUID
    @col.medusa_cfs_directory_id = '7afc3e80-b41b-0134-234d-0050569601ca-7'
    assert !@col.valid?
    # set it to a file UUID
    @col.medusa_cfs_directory_id = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@col.valid?
  end

  # medusa_file_group()

  test 'medusa_file_group() should return nil if medusa_file_group_id is nil' do
    @col.medusa_file_group_id = nil
    assert_nil @col.medusa_file_group
  end

  test 'medusa_file_group() should return a MedusaFileGroup' do
    assert_equal @col.medusa_file_group.uuid, @col.medusa_file_group_id
  end

  # meduse_file_group_id

  test 'medusa_file_group_id must be a valid Medusa file group ID' do
    # set it to a directory UUID
    @col.medusa_file_group_id = '7b1f3340-b41b-0134-234d-0050569601ca-8'
    assert !@col.valid?
    # set it to a file UUID
    @col.medusa_file_group_id = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@col.valid?
  end

  # medusa_repository()

  test 'medusa_repository() should return nil if medusa_repository_id is nil' do
    @col.medusa_repository_id = nil
    assert_nil @col.medusa_repository
  end

  test 'medusa_repository() should return a MedusaRepository' do
    assert_equal @col.medusa_repository.id, @col.medusa_repository_id
  end

  # medusa_url()

  test 'medusa_url() should return nil when the repository ID is nil' do
    @col.repository_id = nil
    assert_nil @col.medusa_url
  end

  # medusa_url()

  test 'medusa_url should return the correct URL' do
    # without format
    expected = sprintf('%s/uuids/%s',
                       Configuration.instance.medusa_url.chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url)

    # with format
    expected = sprintf('%s/uuids/%s.json',
                       Configuration.instance.medusa_url.chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url('json'))
  end

  # migrate_item_elements()

  test 'migrate_item_elements() should raise an error when given a destination
  element that is not present in the metadata profile' do
    assert_raises ArgumentError do
      @col.migrate_item_elements('title', 'bogus')
    end
  end

  test 'migrate_item_elements() should raise an error when source and
  destination elements have different vocabularies' do
    assert_raises ArgumentError do
      @col.migrate_item_elements('title', 'subject')
    end
  end

  test 'migrate_item_elements() should work' do
    test_item = items(:item1)
    test_title = test_item.title
    assert_not_empty test_title
    assert_equal 1, test_item.elements.select{ |e| e.name == 'description' }.length

    @col.migrate_item_elements('title', 'description')

    test_item.reload
    assert_empty test_item.elements.select{ |e| e.name == 'title' }
    assert_equal 2, test_item.elements.select{ |e| e.name == 'description' }.length
  end

  # package_profile()

  test 'package_profile should return a PackageProfile' do
    assert @col.package_profile.kind_of?(PackageProfile)
    @col.package_profile_id = 37
    assert_nil @col.package_profile
  end

  # package_profile=()

  test 'package_profile= should set a PackageProfile' do
    @col.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_equal @col.package_profile_id, PackageProfile::COMPOUND_OBJECT_PROFILE.id
  end

  # replace_item_element_values()

  test 'replace_item_element_values() should work with :exact_match matching
  mode and :whole_value replace mode' do
    # Test match
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @col.replace_item_element_values(:exact_match, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigers')
    item.save!

    @col.replace_item_element_values(:exact_match, 'foxes', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'tigers', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :exact_match matching
  mode and :matched_part replace mode' do
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @col.replace_item_element_values(:exact_match, 'ZZZtigersZZZ', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :contain matching mode
  and :whole_value replace mode' do
    # Test match
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @col.replace_item_element_values(:contain, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'foxes')
    item.save!

    @col.replace_item_element_values(:contain, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'foxes', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :contain matching mode
  and :matched_part replace mode' do
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'ZZZtigersZZZ')
    item.save!

    @col.replace_item_element_values(:contain, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlionsZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :start matching mode and
  :whole_value replace mode' do
    # Test match
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @col.replace_item_element_values(:start, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @col.replace_item_element_values(:start, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'ZZZtigers', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :start matching mode and
  :matched_part replace mode' do
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @col.replace_item_element_values(:start, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'lionsZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with :end matching mode and
  :whole_value replace mode' do
    # Test match
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @col.replace_item_element_values(:end, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'lions', item.element(:cat).value

    # Test no match
    item.elements.clear
    item.elements.build(name: 'cat', value: 'tigersZZZ')
    item.save!

    @col.replace_item_element_values(:end, 'tigers', 'cat', :whole_value, 'lions')

    item.reload
    assert_equal 'tigersZZZ', item.element(:cat).value
  end

  test 'replace_item_element_values() should work with end matching mode and
  matched_part replace mode' do
    item = items(:item1)
    item.elements.build(name: 'cat', value: 'ZZZtigers')
    item.save!

    @col.replace_item_element_values(:end, 'tigers', 'cat', :matched_part, 'lions')

    item.reload
    assert_equal 'ZZZlions', item.element(:cat).value
  end

  # repository_id

  test 'repository_id must be a UUID' do
    @col.repository_id = 123
    assert !@col.valid?

    @col.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
  end

  # solr_id()

  test 'solr_id should return the repository ID' do
    assert_equal @col.repository_id, @col.solr_id
  end

  # to_param()

  test 'to_param should return the repository ID' do
    assert_equal @col.repository_id, @col.to_param
  end

  # to_s()

  test 'to_s should return the title' do
    assert_equal 'd250c1f0-5ca8-0132-3334-0050569601ca-8', @col.title
  end

  # to_solr()

  test 'to_solr return the correct Solr document' do
    doc = @col.to_solr

    assert_equal @col.solr_id, doc[Collection::SolrFields::ID]
    assert_equal @col.class.to_s, doc[Collection::SolrFields::CLASS]
    assert_not_empty doc[Collection::SolrFields::LAST_INDEXED]
    assert_equal @col.access_systems, doc[Collection::SolrFields::ACCESS_SYSTEMS]
    assert_equal @col.access_url, doc[Collection::SolrFields::ACCESS_URL]
    assert_equal @col.allowed_roles.map(&:key).sort,
                 doc[Collection::SolrFields::ALLOWED_ROLES].sort
    assert_equal @col.denied_roles.map(&:key).sort,
                 doc[Collection::SolrFields::DENIED_ROLES].sort
    assert_equal @col.description, doc[Collection::SolrFields::DESCRIPTION]
    assert_equal @col.description_html, doc[Collection::SolrFields::DESCRIPTION_HTML]
    assert_equal @col.harvestable, doc[Collection::SolrFields::HARVESTABLE]
    assert_equal @col.description, doc[Collection::SolrFields::METADATA_DESCRIPTION]
    assert_equal @col.title, doc[Collection::SolrFields::METADATA_TITLE]
    assert_equal @col.published, doc[Collection::SolrFields::PUBLISHED]
    assert_empty doc[Collection::SolrFields::PARENT_COLLECTIONS]
    assert_equal @col.published_in_dls,
                 doc[Collection::SolrFields::PUBLISHED_IN_DLS]
    assert_equal @col.medusa_repository.title,
                 doc[Collection::SolrFields::REPOSITORY_TITLE]
    assert_equal @col.representative_item_id,
                 doc[Collection::SolrFields::REPRESENTATIVE_ITEM]
    assert_equal @col.resource_types, doc[Collection::SolrFields::RESOURCE_TYPES]
    assert_equal @col.title, doc[Collection::SolrFields::TITLE]
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
    c = Collection.new(repository_id: '6ff64b00-072d-0130-c5bb-0019b9e633c5-2')
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
