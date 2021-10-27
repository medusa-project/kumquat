require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  setup do
    setup_elasticsearch
    @collection = collections(:compound_object)
  end

  # Collection.delete_document()

  test 'delete_document() deletes a document' do
    collections = Collection.all.limit(5)
    collections.each(&:reindex)
    refresh_elasticsearch
    count = Collection.search.count
    assert count > 0

    Collection.delete_document(collections.first.index_id)
    refresh_elasticsearch
    assert_equal count - 1, Collection.search.count
  end

  # Collection.delete_orphaned_documents()

  test 'delete_orphaned_documents() works' do
    collections = Collection.all
    collections.each(&:reindex)
    count = collections.count
    refresh_elasticsearch

    collections.first.destroy! # outside of a transaction!

    Collection.delete_orphaned_documents
    refresh_elasticsearch

    assert_equal count - 1, Collection.search.count
  end

  # from_medusa()

  test 'from_medusa() with an invalid ID raises an error' do
    assert_raises ActiveRecord::RecordNotFound do
      Collection.from_medusa('bogus')
    end
  end

  test 'from_medusa() works' do
    uuid = @collection.repository_id
    @collection.destroy!

    @collection = Collection.from_medusa(uuid)
    assert_equal 'Compound Object Collection', @collection.title
  end

  # reindex_all()

  test 'reindex_all() reindexes all collections' do
    Collection.reindex_all
    refresh_elasticsearch

    actual = Collection.search.
        include_unpublished(true).
        include_restricted(true).
        count
    assert actual > 0
    assert_equal Collection.count, actual
  end

  # all_indexed_item_ids()

  test 'all_indexed_item_ids() returns all indexed item IDs' do
    @collection.items.each(&:reindex)
    refresh_elasticsearch
    assert_equal Set.new(['21353276-887c-0f2b-25a0-ed444003303f',
                  '6bc86d3b-e321-1a63-5172-fbf9a6e1aaab',
                  '9dc25346-b83a-eb8a-ac2a-bdde98b5a374',
                  '6a1d73f2-3493-1ca8-80e5-84a49d524f92',
                  '96a95ca7-57b5-3901-1022-2093e33cba3f']),
                 Set.new(@collection.all_indexed_item_ids)
  end

  # as_harvestable_json()

  test 'as_harvestable_json() returns the correct structure' do
    doc = @collection.as_harvestable_json
    assert_equal 'Collection', doc[:class]
    assert_equal @collection.repository_id, doc[:id]
    assert_equal @collection.external_id, doc[:external_id]
    assert_equal @collection.access_url, doc[:access_uri]
    assert_equal @collection.physical_collection_url, doc[:physical_collection_uri]
    assert_equal @collection.medusa_repository.title, doc[:repository_title]
    assert_equal @collection.resource_types, doc[:resource_types]
    assert_equal @collection.access_systems, doc[:access_systems]
    assert_equal @collection.package_profile&.name, doc[:package_profile]
    assert_nil doc[:access_master_image]
    assert_equal @collection.elements_in_profile_order(only_visible: true)
                     .map{ |e| { name: e.name, value: e.value } }, doc[:elements]
    assert_equal @collection.created_at, doc[:created_at]
    assert_equal @collection.updated_at, doc[:updated_at]
  end

  # as_indexed_json()

  test 'as_indexed_json returns the correct structure' do
    doc = @collection.as_indexed_json

    assert_equal @collection.access_systems,
                 doc[Collection::IndexFields::ACCESS_SYSTEMS]
    assert_equal @collection.access_url,
                 doc[Collection::IndexFields::ACCESS_URL]
    assert_equal @collection.allowed_host_groups.pluck(:key).sort,
                 doc[Collection::IndexFields::ALLOWED_HOST_GROUPS].sort
    assert_equal @collection.allowed_host_groups.pluck(:key).length,
                 doc[Collection::IndexFields::ALLOWED_HOST_GROUP_COUNT]
    assert_equal 'Collection',
                 doc[Collection::IndexFields::CLASS]
    assert_equal @collection.denied_host_groups.pluck(:key).sort,
                 doc[Collection::IndexFields::DENIED_HOST_GROUPS].sort
    assert_equal @collection.denied_host_groups.pluck(:key).length,
                 doc[Collection::IndexFields::DENIED_HOST_GROUP_COUNT]
    assert_equal @collection.allowed_host_groups.pluck(:key),
                 doc[Item::IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS]
    assert_equal @collection.allowed_host_groups.pluck(:key).length,
                 doc[Item::IndexFields::EFFECTIVE_ALLOWED_HOST_GROUP_COUNT]
    assert_equal @collection.denied_host_groups.pluck(:key),
                 doc[Item::IndexFields::EFFECTIVE_DENIED_HOST_GROUPS]
    assert_equal @collection.denied_host_groups.pluck(:key).length,
                 doc[Item::IndexFields::EFFECTIVE_DENIED_HOST_GROUP_COUNT]
    assert_equal @collection.external_id,
                 doc[Collection::IndexFields::EXTERNAL_ID]
    assert_equal @collection.harvestable,
                 doc[Collection::IndexFields::HARVESTABLE]
    assert_equal @collection.harvestable_by_idhh,
                 doc[Collection::IndexFields::HARVESTABLE_BY_IDHH]
    assert_equal @collection.harvestable_by_primo,
                 doc[Collection::IndexFields::HARVESTABLE_BY_PRIMO]
    assert_not_empty doc[Collection::IndexFields::LAST_INDEXED]
    assert_equal @collection.updated_at.utc.iso8601,
                 doc[Collection::IndexFields::LAST_MODIFIED]
    assert_empty doc[Collection::IndexFields::PARENT_COLLECTIONS]
    assert_equal @collection.public_in_medusa,
                 doc[Collection::IndexFields::PUBLIC_IN_MEDUSA]
    assert_equal @collection.publicly_accessible?,
                 doc[Collection::IndexFields::PUBLICLY_ACCESSIBLE]
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
      assert_equal [element.value], doc[element.indexed_field]
    end
  end

  # delete_orphaned_item_documents

  test 'delete_orphaned_item_documents() works' do
    @collection.items.each(&:reindex)
    refresh_elasticsearch
    assert_equal 5, Item.search.
        include_unpublished(true).
        include_restricted(true).
        include_children_in_results(true).
        collection(@collection).
        count

    @collection.items.first.destroy! # delete outside of a transaction
    @collection.delete_orphaned_item_documents
    refresh_elasticsearch

    assert_equal 4, Item.search.
        include_unpublished(true).
        include_restricted(true).
        include_children_in_results(true).
        collection(@collection).count
  end

  # effective_medusa_directory

  test 'effective_medusa_directory() returns the instance CFS directory when set' do
    uuid = SecureRandom.uuid
    @collection.medusa_directory_uuid = uuid
    assert_equal uuid, @collection.effective_medusa_directory.uuid
  end

  test 'effective_medusa_directory() falls back to the file group CFS directory' do
    @collection.medusa_directory_uuid  = nil
    @collection.medusa_file_group_uuid = '5881d456-6dbe-90f1-ac81-7e0bf53e9c84'
    @collection.save!
    assert_equal '1b760655-c504-7fce-f171-76e4234844da',
                 @collection.effective_medusa_directory.uuid
  end

  # effective_metadata_profile()

  test 'effective_metadata_profile() returns the assigned metadata profile' do
    assert_equal @collection.metadata_profile,
                 @collection.effective_metadata_profile
  end

  test 'effective_metadata_profile() returns the default metadata
  profile if not assigned' do
    @collection.metadata_profile = nil
    assert_equal MetadataProfile.default, @collection.effective_metadata_profile
  end

  # effective_representative_object()

  test 'effective_representative_object() returns the effective
  representative item when set' do
    item = items(:compound_object_1002_page1)
    @collection.representative_item_id = item.repository_id
    assert_equal item.repository_id,
                 @collection.effective_representative_object.repository_id
  end

  test 'effective_representative_object() should fall back to the instance' do
    @collection.representative_item_id = nil
    assert_same @collection, @collection.effective_representative_object
  end

  # effective_representative_image_binary()

  test 'effective_representative_image_binary() should work' do
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

  test 'item_sets returns all item sets' do
    assert_equal 1, @collection.item_sets.length
  end

  # items()

  test 'items returns all items' do
    assert_equal 5, @collection.items.length
  end

  # medusa_directory()

  test 'medusa_directory() returns nil if medusa_directory_uuid is nil' do
    @collection.medusa_directory_uuid = nil
    assert_nil @collection.medusa_directory
  end

  test 'medusa_directory() returns a Medusa::Directory when medusa_directory_uuid is set' do
    @collection.medusa_directory_uuid = '21353276-887c-0f2b-25a0-ed444003303f'
    assert_equal @collection.medusa_directory.uuid,
                 @collection.medusa_directory_uuid
  end

  # medusa_directory_uuid

  test 'medusa_directory_uuid must be a valid Medusa directory ID' do
    # set it to a file group UUID
    @collection.medusa_directory_uuid = '7afc3e80-b41b-0134-234d-0050569601ca-7'
    assert !@collection.valid?
    # set it to a file UUID
    @collection.medusa_directory_uuid = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@collection.valid?
  end

  # medusa_file_group()

  test 'medusa_file_group() returns nil if medusa_file_group_uuid is nil' do
    @collection.medusa_file_group_uuid = nil
    assert_nil @collection.medusa_file_group
  end

  test 'medusa_file_group() returns a Medusa::FileGroup' do
    assert_equal @collection.medusa_file_group.uuid,
                 @collection.medusa_file_group_uuid
  end

  # meduse_file_group_uuid

  test 'medusa_file_group_uuid must be a valid Medusa file group ID' do
    # set it to a directory UUID
    @collection.medusa_file_group_uuid = '7b1f3340-b41b-0134-234d-0050569601ca-8'
    assert !@collection.valid?
    # set it to a file UUID
    @collection.medusa_file_group_uuid = '6cc533c0-cebf-0134-238a-0050569601ca-3'
    assert !@collection.valid?
  end

  # medusa_repository()

  test 'medusa_repository() returns nil if medusa_repository_id is nil' do
    @collection.medusa_repository_id = nil
    assert_nil @collection.medusa_repository
  end

  test 'medusa_repository() returns a MedusaRepository' do
    assert_equal @collection.medusa_repository.id,
                 @collection.medusa_repository_id
  end

  # medusa_url()

  test 'medusa_url() returns nil when the repository ID is nil' do
    @collection.repository_id = nil
    assert_nil @collection.medusa_url
  end

  # medusa_url()

  test 'medusa_url() returns the correct URL' do
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

  # num_items()

  test 'num_items() works' do
    items = @collection.items
    assert_equal 5, items.length

    items.each(&:reindex)
    refresh_elasticsearch

    assert_equal 5, @collection.num_items
  end

  # num_objects()

  test 'num_objects() works with free-form collections' do
    @collection = collections(:free_form)
    @collection.items.each(&:reindex)
    refresh_elasticsearch
    assert_equal 4, @collection.num_objects
  end

  test 'num_objects() works with non-free-form collections' do
    @collection.items.each(&:reindex)
    refresh_elasticsearch
    assert_equal 2, @collection.num_objects
  end

  # num_public_objects()

  test 'num_public_objects works with free-form collections' do
    @collection = collections(:free_form)
    @collection.items.each do |item|
      # Need to add a title element in order to consider it "described".
      item.elements.build(name: 'title', value: 'Cats')
      item.reindex
    end
    refresh_elasticsearch
    assert_equal 4, @collection.num_public_objects
  end

  test 'num_public_objects works with non-free-form collections' do
    @collection.items.each do |item|
      # Need to add a non-title element in order to consider it "described".
      item.elements.build(name: 'subject', value: 'Cats')
      item.reindex
    end
    refresh_elasticsearch
    assert_equal 2, @collection.num_public_objects
  end

  # package_profile()

  test 'package_profile() returns a PackageProfile' do
    assert @collection.package_profile.kind_of?(PackageProfile)
    @collection.package_profile_id = 37
    assert_nil @collection.package_profile
  end

  # package_profile=()

  test 'package_profile=() sets a PackageProfile' do
    @collection.package_profile = PackageProfile::COMPOUND_OBJECT_PROFILE
    assert_equal @collection.package_profile_id,
                 PackageProfile::COMPOUND_OBJECT_PROFILE.id
  end

  # propagate_heritable_properties()

  test 'propagate_heritable_properties() propagates host groups to items' do
    # Clear all host groups on the collection and its items.
    @collection.allowed_host_groups.destroy_all
    @collection.denied_host_groups.destroy_all
    @collection.save!

    @collection.items.each do |it|
      it.allowed_host_groups.destroy_all
      it.denied_host_groups.destroy_all
      it.save!

      assert_equal 0, it.effective_allowed_host_groups.count
      assert_equal 0, it.effective_denied_host_groups.count
    end

    # Add host groups to the collection.
    @collection.allowed_host_groups << host_groups(:red)
    @collection.denied_host_groups << host_groups(:blue)

    # Propagate heritable properties.
    @collection.propagate_heritable_properties

    # Assert that the collection's items have inherited the host groups.
    @collection.items.each do |it|
      assert_equal 1, it.effective_allowed_host_groups.count
      assert it.effective_allowed_host_groups.include?(host_groups(:red))

      assert_equal 1, it.effective_denied_host_groups.count
      assert it.effective_denied_host_groups.include?(host_groups(:blue))
    end
  end

  # publicly_accessible?()

  test 'publicly_accessible? returns true if the collection is public in
  Medusa and published in DLS' do
    @collection.public_in_medusa = true
    @collection.published_in_dls = true
    assert @collection.publicly_accessible?
  end

  test 'publicly_accessible? returns true if the collection is public in
  Medusa and has an access URL' do
    @collection.public_in_medusa = true
    @collection.access_url = 'http://example.org/'
    assert @collection.publicly_accessible?
  end

  test 'publicly_accessible? returns false if the collection is not public in
  Medusa but is published in DLS' do
    @collection.public_in_medusa = false
    @collection.published_in_dls = true
    assert !@collection.publicly_accessible?
  end

  test 'publicly_accessible? returns false if the collection is not public in
  Medusa but has an access URL' do
    @collection.public_in_medusa = false
    @collection.access_url = 'http://example.org/'
    assert !@collection.publicly_accessible?
  end

  # purge()

  test 'purge purges all items' do
    assert @collection.items.count > 0
    @collection.purge
    assert @collection.items.count == 0
  end

  # reindex()

  test 'reindex reindexes the instance' do
    assert_equal 0, Collection.search.
        filter(Collection::IndexFields::REPOSITORY_ID, @collection.repository_id).count

    @collection.reindex
    refresh_elasticsearch

    assert_equal 1, Collection.search.
        filter(Collection::IndexFields::REPOSITORY_ID, @collection.repository_id).count
  end

  # reindex_items

  test 'reindex_items works' do
    assert_equal 0, Item.search.
        collection(@collection).
        include_unpublished(true).
        include_restricted(true).
        include_children_in_results(true).
        count

    @collection.reindex_items
    refresh_elasticsearch

    assert_equal 5, Item.search.
        collection(@collection).
        include_unpublished(true).
        include_restricted(true).
        include_children_in_results(true).
        count
  end

  # repository()

  test 'repository() returns the repository when medusa_repository_id is set' do
    assert_not_nil @collection.repository
  end

  test 'repository() returns nil when medusa_repository_id is nil' do
    @collection.medusa_repository_id = nil
    assert_nil @collection.repository
  end

  # repository_id

  test 'repository_id must be a UUID' do
    @collection.repository_id = 123
    assert !@collection.valid?

    @collection.repository_id = '8acdb390-96b6-0133-1ce8-0050569601ca-4'
    assert @collection.valid?
  end

  # representative_item()

  test 'representative_item() works' do
    # TODO: write this
  end

  # root_item()

  test 'root_item() returns nil for non-free-form collections' do
    assert_nil collections(:compound_object).root_item
    assert_nil collections(:mixed_media).root_item
    assert_nil collections(:single_item_object).root_item
  end

  test 'root_item() returns nil for free-form collections whose directory is
  the same as the file group directory' do
    assert_nil collections(:free_form).root_item
  end

  test 'root_item() returns an item for free-form collections whose directory
  is different from the same as the file group directory' do
    @collection = collections(:free_form)
    @collection.medusa_directory_uuid = '7351760f-4b7b-5a6c-6dda-f5a92562b008'
    assert_not_nil @collection.root_item
  end

  # to_param()

  test 'to_param returns the repository ID' do
    assert_equal @collection.repository_id, @collection.to_param
  end

  # to_s()

  test 'to_s returns the title element value if available' do
    title = 'My Great Title'
    @collection.elements.destroy_all
    @collection.elements.build(name: 'title', value: title)
    @collection.save!
    assert_equal title, @collection.title
  end

  test 'to_s returns the repository ID if there is no title element' do
    @collection.elements.destroy_all
    assert_equal @collection.repository_id, @collection.title
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
    collection = collections(:compound_object)
    uuid = collection.repository_id
    collection.destroy!

    c = Collection.new(repository_id: uuid)
    c.update_from_medusa

    assert_equal 'Compound Object Collection', c.title
  end

end
