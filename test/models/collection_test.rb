require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    @collection = collections(:sanborn)
    assert @collection.valid?

    ElasticsearchClient.instance.recreate_all_indexes
  end

  # from_medusa()

  test 'from_medusa() with an invalid ID should raise an error' do
    assert_raises ActiveRecord::RecordNotFound do
      Collection.from_medusa('cats')
    end
  end

  test 'from_medusa() should work' do
    uuid = @collection.repository_id
    @collection.destroy!

    @collection = Collection.from_medusa(uuid)
    assert_equal 'Sanborn Fire Insurance Maps', @collection.title
  end

  # reindex_all()

  test 'reindex_all() should reindex all collections' do
    ElasticsearchClient.instance.recreate_index(Collection)

    assert_equal 0, CollectionFinder.new.include_unpublished(true).count

    Collection.reindex_all
    sleep 2 # wait for them to become searchable

    actual = CollectionFinder.new.include_unpublished(true).count
    assert actual > 0
    assert_equal Collection.count, actual
  end

  # as_indexed_json()

  test 'as_indexed_json() returns the correct structure' do
    doc = @collection.as_indexed_json

    assert_equal @collection.access_systems,
                 doc[Collection::IndexFields::ACCESS_SYSTEMS]
    assert_equal @collection.access_url,
                 doc[Collection::IndexFields::ACCESS_URL]
    assert_equal @collection.allowed_roles.map(&:key).sort,
                 doc[Collection::IndexFields::ALLOWED_ROLES].sort
    assert_equal @collection.denied_roles.map(&:key).sort,
                 doc[Collection::IndexFields::DENIED_ROLES].sort
    assert_equal @collection.published,
                 doc[Collection::IndexFields::EFFECTIVELY_PUBLISHED]
    assert_equal @collection.external_id,
                 doc[Collection::IndexFields::EXTERNAL_ID]
    assert_equal @collection.harvestable,
                 doc[Collection::IndexFields::HARVESTABLE]
    assert_not_empty doc[Collection::IndexFields::LAST_INDEXED]
    assert_empty doc[Collection::IndexFields::PARENT_COLLECTIONS]
    assert_equal @collection.public_in_medusa,
                 doc[Collection::IndexFields::PUBLIC_IN_MEDUSA]
    assert_equal @collection.published_in_dls,
                 doc[Collection::IndexFields::PUBLISHED_IN_DLS]
    assert_equal @collection.repository_id,
                 doc[Collection::IndexFields::REPOSITORY_ID]
    assert_equal @collection.medusa_repository.title,
                 doc[Collection::IndexFields::REPOSITORY_TITLE]
    assert_equal @collection.representative_item_id,
                 doc[Collection::IndexFields::REPRESENTATIVE_ITEM]
    assert_equal @collection.resource_types,
                 doc[Collection::IndexFields::RESOURCE_TYPES]

    @collection.elements.each do |element|
      assert_equal element.value, doc[element.indexed_field]
    end
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

  # effective_medusa_cfs_directory

  test 'effective_medusa_cfs_directory() should return the instance CFS
  directory when set' do
    dir = medusa_cfs_directories(:one)
    @collection.medusa_cfs_directory_id = dir.uuid
    assert_equal dir.uuid, @collection.effective_medusa_cfs_directory.uuid
  end

  test 'effective_medusa_cfs_directory() should fall back to the file group CFS
  directory' do
    group = medusa_file_groups(:one)
    @collection.medusa_cfs_directory_id = nil
    @collection.medusa_file_group_id = group.uuid
    @collection.save!
    assert_equal group.cfs_directory.uuid,
                 @collection.effective_medusa_cfs_directory.uuid
  end

  # effective_metadata_profile()

  test 'effective_metadata_profile() should return the assigned metadata
  profile' do
    assert_equal @collection.metadata_profile,
                 @collection.effective_metadata_profile
  end

  test 'effective_metadata_profile() should return the default metadata
  profile if not assigned' do
    @collection.metadata_profile = nil
    assert_equal MetadataProfile.default, @collection.effective_metadata_profile
  end

  # effective_representative_entity()

  test 'effective_representative_entity() should return the effective
  representative item when set' do
    item = items(:sanborn_obj1_page1)
    @collection.representative_item_id = item.repository_id
    assert_equal item.repository_id,
                 @collection.effective_representative_entity.repository_id
  end

  test 'effective_representative_entity() should fall back to the instance' do
    @collection.representative_item_id = nil
    assert_same @collection, @collection.effective_representative_entity
  end

  # effective_representative_image_binary()

  test 'effective_representative_image_binary() should work' do
    # TODO: write this
  end

  # effective_representative_item()

  test 'effective_representative_item() should work' do
    # TODO: write this
  end

  # free_form?()

  test 'free_form?() returns true when the package profile is free-form' do
    @collection.package_profile = PackageProfile::FREE_FORM_PROFILE
    assert @collection.free_form?
  end

  test 'free_form?() returns false when the package profile is not free-form' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert !@collection.free_form?
  end

  # item_sets()

  test 'item_sets should return all item sets' do
    assert_equal 1, @collection.item_sets.length
  end

  # items()

  test 'items should return all items' do
    assert_equal 4, @collection.items.length
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
    assert_equal @collection.medusa_repository.medusa_database_id,
                 @collection.medusa_repository_id
  end

  # medusa_url()

  test 'medusa_url() should return nil when the repository ID is nil' do
    @collection.repository_id = nil
    assert_nil @collection.medusa_url
  end

  # medusa_url()

  test 'medusa_url() should return the correct URL' do
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

  # num_items()

  test 'num_items() works' do
    items = @collection.items
    assert_equal 4, items.length

    items.each(&:reindex)

    sleep 2 # wait for them to become searchable
    assert_equal 4, @collection.num_items
  end

  # num_objects()

  test 'num_objects() works with free-form collections' do
    @collection = collections(:illini_union)
    @collection.items.each(&:reindex)
    sleep 2 # wait for them to become searchable
    assert_equal 1, @collection.num_objects
  end

  test 'num_objects() works with non-free-form collections' do
    @collection.items.each(&:reindex)
    sleep 2 # wait for them to become searchable
    assert_equal 2, @collection.num_objects
  end

  # num_public_objects()

  test 'num_public_objects() works with free-form collections' do
    @collection = collections(:illini_union)
    @collection.items.each do |item|
      # Need to add a title element in order to consider it "described".
      item.elements.build(name: 'title', value: 'Cats')
      item.reindex
    end
    sleep 2 # wait for them to become searchable
    assert_equal 1, @collection.num_public_objects
  end

  test 'num_public_objects() works with non-free-form collections' do
    @collection.items.each do |item|
      # Need to add a non-title element in order to consider it "described".
      item.elements.build(name: 'subject', value: 'Cats')
      item.reindex
    end
    sleep 2 # wait for them to become searchable
    assert_equal 2, @collection.num_public_objects
  end

  # package_profile()

  test 'package_profile() should return a PackageProfile' do
    assert @collection.package_profile.kind_of?(PackageProfile)
    @collection.package_profile_id = 37
    assert_nil @collection.package_profile
  end

  # package_profile=()

  test 'package_profile=() should set a PackageProfile' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_equal @collection.package_profile_id,
                 PackageProfile::COMPOUND_OBJECT_PROFILE.id
  end

  # propagate_heritable_properties()

  test 'propagate_heritable_properties() should propagate roles to items' do
    # Clear all roles on the collection and its items.
    @collection.allowed_roles.destroy_all
    @collection.denied_roles.destroy_all
    @collection.save!

    @collection.items.each do |it|
      it.allowed_roles.destroy_all
      it.denied_roles.destroy_all
      it.save!

      assert_equal 0, it.effective_allowed_roles.count
      assert_equal 0, it.effective_denied_roles.count
    end

    # Add roles to the collection.
    @collection.allowed_roles << roles(:admins)
    @collection.denied_roles << roles(:catalogers)

    # Propagate heritable properties.
    @collection.propagate_heritable_properties

    # Assert that the collection's items have inherited the roles.
    @collection.items.each do |it|
      assert_equal 1, it.effective_allowed_roles.count
      assert it.effective_allowed_roles.include?(roles(:admins))

      assert_equal 1, it.effective_denied_roles.count
      assert it.effective_denied_roles.include?(roles(:catalogers))
    end
  end

  # published()

  test 'published() returns true if the collection is public in Medusa and
  published in DLS' do
    @collection.public_in_medusa = true
    @collection.published_in_dls = true
    assert @collection.published
  end

  test 'published() returns true if the collection is public in Medusa and has
  an access URL' do
    @collection.public_in_medusa = true
    @collection.access_url = 'http://example.org/'
    assert @collection.published
  end

  test 'published() returns false if the collection is not public in Medusa and
  published in DLS' do
    @collection.public_in_medusa = false
    @collection.published_in_dls = true
    assert !@collection.published
  end

  test 'published() returns false if the collection is not public in Medusa and
  has an access URL' do
    @collection.public_in_medusa = false
    @collection.access_url = 'http://example.org/'
    assert !@collection.published
  end

  # purge()

  test 'purge() should purge all items' do
    assert @collection.items.count > 0
    @collection.purge
    assert @collection.items.count == 0
  end

  # reindex()

  test 'reindex() reindexes the instance' do
    assert_equal 0, CollectionFinder.new.
        filter(Collection::IndexFields::REPOSITORY_ID, @collection.repository_id).count

    @collection.reindex
    sleep 2 # wait for it to become searchable

    assert_equal 1, CollectionFinder.new.
        filter(Collection::IndexFields::REPOSITORY_ID, @collection.repository_id).count
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

  # representative_image_binary()

  test 'representative_image_binary() should work' do
    # TODO: write this
  end

  # representative_item()

  test 'representative_item() should work' do
    # TODO: write this
  end

  # to_param()

  test 'to_param should return the repository ID' do
    assert_equal @collection.repository_id, @collection.to_param
  end

  # to_s()

  test 'to_s should return the title element value if available' do
    title = 'My Great Title'
    @collection.elements.destroy_all
    @collection.elements.build(name: 'title', value: title)
    @collection.save!
    assert_equal title, @collection.title
  end

  test 'to_s should return the repository ID if there is no title element' do
    @collection.elements.destroy_all
    assert_equal '6ff64b00-072d-0130-c5bb-0019b9e633c5-2', @collection.title
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

end
