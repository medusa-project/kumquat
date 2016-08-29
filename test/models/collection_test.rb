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

  # items()

  test 'items should return all items' do
    assert_equal 7, @col.items.length
  end

  # items_as_tsv()

  test 'items_as_tsv should work' do
    expected = "uuid\t"\
    "parentId\t"\
    "preservationMasterPathname\t"\
    "accessMasterPathname\t"\
    "variant\t"\
    "pageNumber\t"\
    "subpageNumber\t"\
    "latitude\t"\
    "longitude\t"\
    "string:uncontrolled:title\t"\
    "uri:uncontrolled:title\t"\
    "string:uncontrolled:description\t"\
    "uri:uncontrolled:description\t"\
    "string:lcsh:subject\t"\
    "uri:lcsh:subject\t"\
    "string:tgm:subject\t"\
    "uri:tgm:subject\n"\
    "6e406030-5ce3-0132-3334-0050569601ca-3\ta53add10-5ca8-0132-3334-0050569601ca-7\t\t\tFile\t\t\t\t\t\t\t\t\t\t\t\t\n"\
    "d29950d0-c451-0133-1d17-0050569601ca-2\tbe8d3500-c451-0133-1d17-0050569601ca-9\tMyString\tMyString\t\t\t\t\t\t\t\t\t\t\t\t\t\n"\
    "d29edba0-c451-0133-1d17-0050569601ca-c\tbe8d3500-c451-0133-1d17-0050569601ca-9\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\n"\
    "a1234567-5ca8-0132-3334-0050569601ca-8\t\tMyString\tMyString\t\t\t\t39.2524300\t-152.2342300\t\t\t\t\tCats\t\tMore cats\t\n"\
    "be8d3500-c451-0133-1d17-0050569601ca-9\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\n"\
    "a53add10-5ca8-0132-3334-0050569601ca-7\t\t\t\tDirectory\t\t\t\t\t\t\t\t\t\t\t\t\n"\
    "cd2d4601-c451-0133-1d17-0050569601ca-8\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\n"
    assert_equal expected, @col.items_as_tsv
  end

  # medusa_cfs_directory_id

  test 'medusa_cfs_directory_id must be a UUID' do
    @col.medusa_cfs_directory_id = 123
    assert !@col.valid?

    @col.medusa_cfs_directory_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
  end

  # meduse_file_group_id

  test 'medusa_file_group_id must be a UUID' do
    @col.medusa_file_group_id = 123
    assert !@col.valid?

    @col.medusa_file_group_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @col.valid?
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
    @col.package_profile = PackageProfile::MAP_PROFILE
    assert_equal @col.package_profile_id, PackageProfile::MAP_PROFILE.id
  end

  # medusa_url()

  test 'medusa_url should return the correct URL' do
    # without format
    expected = sprintf('%s/uuids/%s',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url)

    # with format
    expected = sprintf('%s/uuids/%s.json',
                       PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                       @col.repository_id)
    assert_equal(expected, @col.medusa_url('json'))
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
    assert_equal 'MyString', @col.title
  end

  # to_solr()

  test 'to_solr return the correct Solr document' do
    doc = @col.to_solr

    assert_equal @col.solr_id, doc[Collection::SolrFields::ID]
    assert_equal @col.class.to_s, doc[Collection::SolrFields::CLASS]
    assert_not_empty doc[Collection::SolrFields::LAST_INDEXED]
    assert_equal @col.access_systems, doc[Collection::SolrFields::ACCESS_SYSTEMS]
    assert_equal @col.access_url, doc[Collection::SolrFields::ACCESS_URL]
    assert_equal @col.description, doc[Collection::SolrFields::DESCRIPTION]
    assert_equal @col.description_html, doc[Collection::SolrFields::DESCRIPTION_HTML]
    assert_equal @col.published, doc[Collection::SolrFields::PUBLISHED]
    assert_equal @col.published_in_dls, doc[Collection::SolrFields::PUBLISHED_IN_DLS]
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

end
