##
# Encapsulates a Medusa collection.
#
# Collections are identified by their repository ID (`repository_id`), which
# is a UUID matching their Medusa UUID.
#
# Collections can contain zero or more items. (This is a weak relationship;
# the collections don't literally contain them, but items maintain a reference
# to their owning collection's repository ID.)
#
# Collections are associated with a {MetadataProfile}, which defines the list
# of elements that contained items are supposed to have, as well as a
# {PackageProfile} , which defines how collection content is structured in
# Medusa in terms of its file/directory layout.
#
# Collections are searchable via ActiveRecord as well as via Elasticsearch (see
# below).
#
# # Indexing
#
# Instances are automatically indexed in ES (see {as_indexed_json}) in an
# `after_commit` callback. A low-level interface to Elasticsearch is provided
# by ElasticsearchClient, but in most cases, it's better to use the
# higher-level query interface provided by CollectionFinder, which is easier
# to use, and takes authorization, public visiblity, etc. into account.
#
# **IMPORTANT**: Instances are automatically indexed in Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed on save.
# For this reason, **instances should always be created, updated, and deleted
# within transactions.**
#
# # Attributes
#
# * `access_systems`           Access systems through which the collection is
#                              accessible. Copied from Medusa.
# * `access_url`               URL at which the collection's contents are
#                              available, for collections whose content resides
#                              outside the DLS.
# * `contentdm_alias`          String alias of collections that have been
#                              migrated out of CONTENTdm, used for URL
#                              redirection.
# * `created_at`               Managed by ActiveRecord.
# * `description_html`         HTML-formatted description, copied from Medusa.
#                              N.B. There may also be a description element in
#                              the `elements` relationship containing a plain
#                              text description, also copied from Medusa.
# * `descriptive_element_id`   ID of a MetadataProfileElement whose values are
#                              used in the description boxes in results view.
# * `external_id               Value of the Medusa "external ID" field.
# * `harvestable               Controls visiblity of the collection's contents
#                              in the OAI-PMH (or whatever) harvesting
#                              endpoints.
# * `medusa_cfs_directory_id`  Medusa UUID of the root directory in which the
#                              collection's contents reside. If nil, the root
#                              directory of the file group will be used.
# * `medusa_file_group_id`     Medusa UUID of the file group in which the
#                              collection's contents reside.
# * `medusa_repository_id`
# * `metadata_profile_id`      Database ID of the MetadataProfile assigned to
#                              the collection.
# * `package_profile_id`       ID of the PackageProfile assigned to the
#                              collection. The content in the effective root
#                              directory of the collection must conform to this
#                              profile.
# * `physical_collection_url`  URL of the collection's archival collection
#                              counterpart.
# * `public_in_medusa`         Whether the access level of the collection's
#                              metadata is set to "public." This and
#                              `published_in_dls` must be true in order for the
#                              collection or any or any of its items to be
#                              publicly accessible.
# * `published_in_dls`         Whether the collection's content resides in the
#                              DLS, or somewhere else.
#                              N.B.: use `publicly_accessible?()` to test a
#                              collection's effective public accessibility.
# * `repository_id`            The collection's effective UUID, copied from
#                              Medusa.
# * `representative_image`     UUID of a Medusa image file representing the
#                              collection for use in e.g. thumbnails.
#                              `representative_item_id` should be used instead,
#                              if possible.
# * `representative_item_id`   Repository ID of an Item representating the
#                              collection for use in e.g. thumbnails.
# * `resource_types`           Serialized array of resource types contained
#                              within the collection, copied from Medusa.
# * `rights_statement`         Rights statement text.
#                              TODO: store this in an accessRights CollectionElement
# * `rightsstatements_org_uri` URI of a RightsStatements.org statement.
#                              TODO: store this in an accessRights CollectionElement
# * `updated_at`               Managed by ActiveRecord.
#
# Attribute Propagation
#
# Changes to some of a collection's properties, such as `allowed_roles` and
# `denied_roles`, must be propagated to all of its items. This can be done
# using {propagate_heritable_properties}.
#
class Collection < ApplicationRecord

  include AuthorizableByRole
  include Describable
  include Representable

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    ACCESS_SYSTEMS               = 'sys_k_access_systems'
    ACCESS_URL                   = 'sys_k_access_url'
    ALLOWED_ROLE_COUNT           = 'sys_i_allowed_role_count'
    ALLOWED_ROLES                = 'sys_k_allowed_roles'
    CLASS                        = ElasticsearchIndex::StandardFields::CLASS
    DENIED_ROLE_COUNT            = 'sys_i_denied_role_count'
    DENIED_ROLES                 = 'sys_k_denied_roles'
    DESCRIPTION                  = CollectionElement.new(name: 'description').indexed_field
    EFFECTIVE_ALLOWED_ROLE_COUNT = 'sys_i_effective_allowed_role_count'
    EFFECTIVE_ALLOWED_ROLES      = 'sys_k_effective_allowed_roles'
    EFFECTIVE_DENIED_ROLE_COUNT  = 'sys_i_effective_denied_role_count'
    EFFECTIVE_DENIED_ROLES       = 'sys_k_effective_denied_roles'
    EXTERNAL_ID                  = 'sys_k_external_id'
    HARVESTABLE                  = 'sys_b_harvestable'
    LAST_INDEXED                 = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED                = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    NATIVE                       = 'sys_b_native'
    PARENT_COLLECTIONS           = 'sys_k_parent_collections'
    PUBLIC_IN_MEDUSA             = 'sys_b_public_in_medusa'
    PUBLICLY_ACCESSIBLE          = ElasticsearchIndex::StandardFields::PUBLICLY_ACCESSIBLE
    PUBLISHED_IN_DLS             = 'sys_b_published_in_dls'
    REPOSITORY_ID                = 'sys_k_repository_id'
    REPOSITORY_TITLE             = 'sys_k_repository_title'
    REPRESENTATIVE_IMAGE         = 'sys_k_representative_image'
    REPRESENTATIVE_ITEM          = 'sys_k_representative_item'
    RESOURCE_TYPES               = 'sys_k_resource_types'
    SEARCH_ALL                   = ElasticsearchIndex::StandardFields::SEARCH_ALL
    TITLE                        = CollectionElement.new(name: 'title').indexed_keyword_field
  end

  LOGGER = CustomLogger.new(Collection)

  serialize :access_systems
  serialize :resource_types

  belongs_to :descriptive_element, class_name: 'MetadataProfileElement'
  belongs_to :metadata_profile, inverse_of: :collections

  # See CollectionJoin for an explanation of why we don't join on database IDs.
  has_many :child_collection_joins, class_name: 'CollectionJoin',
           primary_key: :repository_id, foreign_key: :parent_repository_id,
           dependent: :destroy
  has_many :children, through: :child_collection_joins,
           source: :child_collection
  has_many :elements, class_name: 'CollectionElement', inverse_of: :collection,
           dependent: :destroy
  has_many :parent_collection_joins, class_name: 'CollectionJoin',
           primary_key: :repository_id, foreign_key: :child_repository_id,
           dependent: :destroy
  has_many :parents, through: :parent_collection_joins,
           source: :parent_collection

  has_and_belongs_to_many :allowed_roles, class_name: 'Role',
                          association_foreign_key: :allowed_role_id
  has_and_belongs_to_many :denied_roles, class_name: 'Role',
                          association_foreign_key: :denied_role_id

  validates_format_of :repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid'
  validate :validate_medusa_uuids

  before_validation :do_before_validation

  # This is commented out because, even though it has to happen, it is
  # potentially very time-consuming. CollectionsController.update() is
  # currently the only means by which collections are updated, so it will
  # invoke this method in a background task.
  #
  #after_update :propagate_host_authorization

  after_commit :index_in_elasticsearch, on: [:create, :update]
  after_commit :delete_from_elasticsearch, on: :destroy

  ##
  # Normally this method should not be used except to delete orphaned documents
  # with no database counterpart. Documents are automatically deleted in an
  # ActiveRecord callback.
  #
  def self.delete_document(repository_id)
    query = {
        query: {
            bool: {
                filter: [
                    {
                        term: {
                            Collection::IndexFields::REPOSITORY_ID => repository_id
                        }
                    }
                ]
            }
        }
    }
    ElasticsearchClient.instance.delete_by_query(JSON.generate(query))
  end

  ##
  # Iterates through all indexed Collection documents and deletes any for which
  # no counterpart exists in the database.
  #
  # Normally this method should not be used except to delete orphaned documents
  # with no database counterpart. See the class documentation for info about
  # how documents are normally deleted.
  #
  def self.delete_orphaned_documents
    start_time = Time.now

    # Get the document count.
    finder = CollectionFinder.new.
        aggregations(false).
        include_unpublished(true).
        limit(0)
    count = finder.count

    # Retrieve document IDs in batches.
    index = start = num_deleted = 0
    limit = 1000
    while start < count do
      ids = finder.start(start).limit(limit).to_id_a
      ids.each do |id|
        unless Collection.exists?(repository_id: id)
          Collection.delete_document(id)
          num_deleted += 1
        end
        index += 1
        StringUtils.print_progress(start_time, index, count,
                                   'Deleting stale documents')
      end
      start += limit
    end
    puts "\nDeleted #{num_deleted} documents"
  end

  ##
  # @return [Enumerable<Hash>] Array of hashes with `:name`, `:label`, and `id`
  #                            keys in the order they should appear.
  #
  def self.facet_fields
    [
        { name: IndexFields::REPOSITORY_TITLE, label: 'Repository',
          id: 'dl-repository-facet' },
        { name: IndexFields::RESOURCE_TYPES, label: 'Resource Type',
          id: 'dl-resource-type-facet' },
        { name: IndexFields::ACCESS_SYSTEMS, label: 'Access Systems',
          id: 'dl-access-systems-facet' }
    ]
  end

  ##
  # @param id [Integer] Medusa collection ID
  # @return [Collection]
  #
  def self.from_medusa(id)
    col = Collection.new
    col.repository_id = id
    col.update_from_medusa
    col
  end

  ##
  # N.B.: Orphaned documents are not deleted; for that, use
  # {delete_orphaned_documents}.
  #
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def self.reindex_all(index = nil)
    Collection.uncached do
      start_time = Time.now
      count = Collection.count
      Collection.all.find_each.with_index do |col, i|
        col.reindex(index)
        StringUtils.print_progress(start_time, i, count, 'Indexing collections')
      end
    end
  end

  ##
  # @return [Enumerable<String>] Enumerable of all {Item} repository IDs
  #                              corresponding to items contained in this
  #                              collection. Item instances may or may not
  #                              exist in the database for each one.
  #
  def all_indexed_item_ids
    json = Jbuilder.encode do |j|
      j._source [ Item::IndexFields::REPOSITORY_ID ]
      j.query do
        j.term do
          j.set! Item::IndexFields::COLLECTION, self.repository_id
        end
      end
      j.from 0
      j.size 999999
    end
    result = ElasticsearchClient.instance.query(json)
    struct = JSON.parse(result)
    puts struct
    struct['hits']['hits'].map{ |r| r['_source'][Item::IndexFields::REPOSITORY_ID] }
  end

  ##
  # N.B.: Changing the implementation normally requires adding a new index
  # schema version.
  #
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json(options = {})
    doc = {}
    doc[IndexFields::ACCESS_SYSTEMS] = self.access_systems
    doc[IndexFields::ACCESS_URL] = self.access_url
    doc[IndexFields::ALLOWED_ROLES] = self.allowed_roles.pluck(:key)
    doc[IndexFields::ALLOWED_ROLE_COUNT] = doc[IndexFields::ALLOWED_ROLES].length
    doc[IndexFields::CLASS] = self.class.to_s
    doc[IndexFields::DENIED_ROLES] = self.denied_roles.pluck(:key)
    doc[IndexFields::DENIED_ROLE_COUNT] = doc[IndexFields::DENIED_ROLES].length
    doc[IndexFields::EFFECTIVE_ALLOWED_ROLES] =
        doc[IndexFields::ALLOWED_ROLES]
    doc[IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT] =
        doc[IndexFields::ALLOWED_ROLE_COUNT]
    doc[IndexFields::EFFECTIVE_DENIED_ROLES] =
        doc[IndexFields::DENIED_ROLES]
    doc[IndexFields::EFFECTIVE_DENIED_ROLE_COUNT] =
        doc[IndexFields::DENIED_ROLE_COUNT]
    doc[IndexFields::EXTERNAL_ID] = self.external_id
    doc[IndexFields::HARVESTABLE] = self.harvestable
    doc[IndexFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::NATIVE] = self.package_profile_id.present?
    doc[IndexFields::PARENT_COLLECTIONS] =
        self.parent_collection_joins.pluck(:parent_repository_id)
    doc[IndexFields::PUBLIC_IN_MEDUSA] = self.public_in_medusa
    doc[IndexFields::PUBLICLY_ACCESSIBLE] = self.publicly_accessible?
    doc[IndexFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[IndexFields::REPOSITORY_ID] = self.repository_id
    doc[IndexFields::REPOSITORY_TITLE] = self.medusa_repository&.title
    doc[IndexFields::REPRESENTATIVE_ITEM] = self.representative_item_id
    doc[IndexFields::RESOURCE_TYPES] = self.resource_types

    self.elements.each do |element|
      # Skip non-indexable elements. Elements are considered indexable if they
      # are marked as indexed in the collection's metadata profile, or if the
      # collection doesn't have a metadata profile.
      next unless (!self.metadata_profile or self.metadata_profile.elements.
          select{ |mpe| mpe.name == element.name }.first&.indexed)

      unless doc[element.indexed_field]&.respond_to?(:each)
        doc[element.indexed_field] = []
      end
      doc[element.indexed_field] <<
          StringUtils.strip_leading_articles(element.value)[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  ##
  # Satisfies the AuthorizableByRole module contract.
  #
  alias_method :effective_allowed_roles, :allowed_roles

  ##
  # Satisfies the AuthorizableByRole module contract.
  #
  alias_method :effective_denied_roles, :denied_roles

  ##
  # Deletes indexed documents whose corresponding Items no longer exist in the
  # database.
  #
  def delete_orphaned_item_documents
    item_ids     = all_indexed_item_ids
    count        = item_ids.length
    orphaned_ids = []
    start_time   = Time.now

    item_ids.each_with_index do |id, index|
      unless Item.find_by_repository_id(id)
        orphaned_ids << id
      end
      StringUtils.print_progress(start_time, index, count,
                                 'Finding orphaned documents')
    end

    if orphaned_ids.any?
      query = Jbuilder.encode do |j|
        j.query do
          j.terms do
            j.set! Item::IndexFields::REPOSITORY_ID, orphaned_ids
          end
        end
      end
      ElasticsearchClient.instance.delete_by_query(query)
    end
  end

  ##
  # The effective CFS directory of the instance -- either one that is directly
  # assigned, or the root CFS directory of the file group.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see medusa_cfs_directory
  #
  def effective_medusa_cfs_directory
    self.medusa_cfs_directory || self.medusa_file_group&.cfs_directory
  end

  ##
  # @return [MetadataProfile] The profile assigned to the instance, or the
  #                           default profile if none is assigned.
  #
  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  ##
  # @return [Item, Collection]
  #
  def effective_representative_entity
    self.effective_representative_item || self
  end

  ##
  # @return [Binary,nil] Best representative image binary based on the
  #                      representative item set in Medusa, if available, or
  #                      the representative image, if not.
  # @see representative_image_binary
  #
  def effective_representative_image_binary
    bin = self.representative_item&.effective_image_binary
    unless bin
      begin
        bin = self.representative_image_binary
      rescue => e
        LOGGER.warn('effective_representative_image_binary(): %s', e)
      end
    end
    bin
  end

  ##
  # @return [Item, nil] Item that effectively represents the instance.
  # @see representative_item
  #
  def effective_representative_item
    item = self.representative_item
    unless item
      begin
        item = self.representative_image_binary&.item
      rescue => e
        LOGGER.warn('effective_representative_item(): %s', e)
      end
    end
    item
  end

  ##
  # @param options [Hash]
  # @option options [Boolean] :only_visible
  # @return [Enumerable<CollectionElement>] The instance's {CollectionElement
  #         metadata elements} in the order of the elements in the instance's
  #         metadata profile. If there is no associated metadata profile, all
  #         elements are returned.
  #
  def elements_in_profile_order(options = {})
    elements = []
    profile = self.metadata_profile
    if profile
      mp_elements = profile.elements
      if options[:only_visible]
        mp_elements = mp_elements.where(visible: true)
      end
      mp_elements.each do |mpe|
        element = self.element(mpe.name)
        elements << element if element
      end
    else
      elements = self.elements
    end
    elements
  end

  ##
  # @return [Boolean]
  #
  def free_form?
    self.package_profile_id == PackageProfile::FREE_FORM_PROFILE.id
  end

  ##
  # @return [Enumerable<ItemSet>]
  #
  def item_sets
    ItemSet.where(collection_repository_id: self.repository_id)
  end

  ##
  # @return [ActiveRecord::Relation<Item>] All items in the collection.
  #
  def items
    Item.where(collection_repository_id: self.repository_id)
  end

  ##
  # The CFS directory in which content resides. This may be the same as the
  # root CFS directory of the file group, or deeper within it. This is used
  # as a refinement of {medusa_file_group}.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see effective_medusa_cfs_directory
  #
  def medusa_cfs_directory
    unless @cfs_directory
      @cfs_directory = nil
      if self.medusa_cfs_directory_id.present?
        @cfs_directory = MedusaCfsDirectory.with_uuid(self.medusa_cfs_directory_id)
      end
    end
    @cfs_directory
  end

  ##
  # @return [MedusaFileGroup]
  #
  def medusa_file_group
   unless @file_group
     @file_group = nil
     if self.medusa_file_group_id.present?
       @file_group = MedusaFileGroup.with_uuid(self.medusa_file_group_id)
     end
   end
   @file_group
  end

  ##
  # @return [MedusaRepository]
  #
  def medusa_repository
    unless @medusa_repository
      @medusa_repository = nil
      if self.medusa_repository_id.present?
        @medusa_repository = MedusaRepository.with_medusa_database_id(
            self.medusa_repository_id)
      end
    end
    @medusa_repository
  end

  ##
  # @param format [String] URL extension like `json`
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  #                  if the instance does not have an ID.
  #
  def medusa_url(format = nil)
    format = format.present? ? ".#{format.to_s.gsub('.', '')}" : ''
    url = nil
    if self.repository_id
      url = sprintf('%s/uuids/%s%s',
                    Configuration.instance.medusa_url.chomp('/'),
                    self.repository_id,
                    format)
    end
    url
  end

  ##
  # Returns the number of items in the collection regardless of hierarchy
  # level or public accessibility. The result is cached.
  #
  # @return [Integer]
  #
  def num_items
    unless @num_items
      @num_items = ItemFinder.new.
          collection(self).
          aggregations(false).
          search_children(true).
          include_unpublished(true).
          order(false).
          limit(0).
          count
    end
    @num_items
  end

  ##
  # Returns the number of objects in the collection. (For free-form
  # collections, an "object" is any file-variant {Item}; for other collections,
  # it is any top-level {Item}.) The result is cached.
  #
  # @return [Integer]
  #
  def num_objects
    unless @num_objects
      finder = ItemFinder.new.
          collection(self).
          aggregations(false).
          include_unpublished(true).
          order(false).
          limit(0)
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_objects = finder.
              include_variants(*Item::Variants::FILE).
              include_children_in_results(true).
              count
        else
          @num_objects = finder.search_children(false).count
      end
    end
    @num_objects
  end

  ##
  # @return [Integer] Number of public objects in the collection.
  #                   The result is cached.
  #
  def num_public_objects
    unless @num_public_objects
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_public_objects = ItemFinder.new.
              collection(self).
              aggregations(false).
              include_variants(*Item::Variants::FILE).
              include_children_in_results(true).
              count
        else
          @num_public_objects = ItemFinder.new.
              collection(self).
              aggregations(false).
              search_children(false).
              count
      end
    end
    @num_public_objects
  end

  ##
  # @return [PackageProfile, nil]
  #
  def package_profile
    self.package_profile_id.present? ?
        PackageProfile.find(self.package_profile_id) : nil
  end

  ##
  # @param profile [PackageProfile]
  #
  def package_profile=(profile)
    self.package_profile_id = profile.kind_of?(PackageProfile) ?
        profile.id : nil
  end

  ##
  # Propagates allowed and denied roles from the instance to all of its items.
  # This is an O(n) operation.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_heritable_properties(task = nil)
    ActiveRecord::Base.transaction do
      num_items = self.items.count
      self.items.each_with_index do |item, index|
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Boolean] The instance's effective public accessibility status.
  #
  def publicly_accessible?
    public_in_medusa and (published_in_dls or access_url.present?)
  end

  ##
  # Deletes all items in the collection. Does not commit the index.
  #
  # @return [Integer] Number of items purged.
  #
  def purge
    items = self.items
    count = items.count
    ActiveRecord::Base.transaction do
      items.destroy_all
    end
    count
  end

  ##
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def reindex(index = nil)
    index_in_elasticsearch(index)
  end

  def reindex_items
    # Reindex all database items.
    puts "Step 1/2"
    start_time = Time.now
    items      = Item.where(collection_repository_id: self.repository_id)
    count      = items.count
    items.each_with_index do |item, index|
      item.reindex
      StringUtils.print_progress(start_time, index, count,
                                 'Reindexing collection items')
    end

    # Delete indexed documents of items no longer present in the database.
    puts "Step 2/2"
    delete_orphaned_item_documents
  end

  ##
  # @return [Binary, nil] Binary corresponding to the `representative_image`
  #                       attribute.
  #
  def representative_image_binary
    binary = nil
    if self.representative_image.present?
      # This may be nil, which may mean that it resides in a different file
      # group, or doesn't comply with the package profile.
      binary = Binary.find_by_cfs_file_uuid(self.representative_image)
      unless binary
        # This may be very expensive!
        cfs_file = MedusaCfsFile.with_uuid(self.representative_image)
        binary = cfs_file.to_binary(Binary::MasterType::ACCESS)
        binary.save!
      end
    end
    binary
  end

  ##
  # @return [Item, nil] Item assigned to represent the instance. May be nil.
  # @see effective_representative_item
  #
  def representative_item
    item = nil
    if self.representative_item_id.present?
      item = Item.find_by_repository_id(self.representative_item_id)
    end
    item
  end

  ##
  # @return [RightsStatement, nil]
  #
  def rightsstatements_org_statement
    RightsStatement.for_uri(self.rightsstatements_org_uri)
  end

  ##
  # @return [Item, nil] If the instance is free-form and uses a subdirectory
  #                     within a file group, that corresponding {Item}.
  #                     Otherwise, nil.
  #
  def root_item
    if free_form? and medusa_cfs_directory_id.present?
      return Item.where(collection_repository_id: self.repository_id)
                 .where(parent_repository_id: nil)
                 .limit(1)
                 .first
    end
    nil
  end

  def to_param
    self.repository_id
  end

  def to_s
    self.title
  end

  ##
  # @return [void]
  # @raises [ActiveRecord::RecordNotFound]
  #
  def update_from_medusa
    unless self.repository_id
      raise ActiveRecord::RecordNotFound,
            'update_from_medusa() called without repository_id set'
    end
    client = MedusaClient.new
    response = client.get(self.medusa_url('json'))
    json_str = response.body
    begin
      struct = JSON.parse(json_str)
    rescue JSON::ParserError => e
      if e.message.include?('UUID not found')
        raise ActiveRecord::RecordNotFound, self.repository_id
      end
      raise e
    end

    ActiveRecord::Base.transaction do
      self.elements.destroy_all

      self.access_systems = struct['access_systems'].map{ |t| t['name'] }
      self.access_url = struct['access_url']
      if struct['description'].present?
        self.elements.build(name: 'description', value: struct['description'])
      end
      self.description_html = struct['description_html']
      self.external_id = struct['external_id']
      self.medusa_repository_id = struct['repository_path'].gsub(/[^0-9+]/, '').to_i
      self.physical_collection_url = struct['physical_collection_url']
      self.public_in_medusa = struct['publish']
      self.representative_image = struct['representative_image']
      self.representative_item_id = struct['representative_item']
      self.resource_types = struct['resource_types'].map do |t| # titleize these
        t['name'].split(' ').map{ |t| t.present? ? t.capitalize : '' }.join(' ')
      end
      self.rights_statement = struct['rights']['custom_copyright_statement']
      self.elements.build(name: 'title', value: struct['title'])

      self.parents.destroy_all
      struct['parent_collections'].each do |parent_struct|
        self.parent_collection_joins.build(parent_repository_id: parent_struct['uuid'],
                                           child_repository_id: self.repository_id)
      end

      self.children.destroy_all
      struct['child_collections'].each do |child_struct|
        self.child_collection_joins.build(parent_repository_id: self.repository_id,
                                          child_repository_id: child_struct['uuid'])
      end

      self.save!
    end
  end

  private

  def delete_from_elasticsearch
    self.class.delete_document(self.repository_id)
  end

  def do_before_validation
    self.medusa_cfs_directory_id&.strip!
    self.medusa_file_group_id&.strip!
    self.representative_image&.strip!
    self.representative_item_id&.strip!
  end

  ##
  # @param index [String] Index name. If omitted, the default index is used.
  # @return [void]
  #
  def index_in_elasticsearch(index = nil)
    index ||= Configuration.instance.elasticsearch_index
    ElasticsearchClient.instance.index_document(index,
                                                self.repository_id,
                                                self.as_indexed_json)
  end

  def validate_medusa_uuids
    client = MedusaClient.new
    if self.medusa_file_group_id.present? and
        self.medusa_file_group_id_changed? and
        client.class_of_uuid(self.medusa_file_group_id) != MedusaFileGroup
      errors.add(:medusa_file_group_id, 'is not a Medusa file group UUID')
    end
    if self.medusa_cfs_directory_id.present? and
        self.medusa_cfs_directory_id_changed? and
        client.class_of_uuid(self.medusa_cfs_directory_id) != MedusaCfsDirectory
      errors.add(:medusa_cfs_directory_id, 'is not a Medusa directory UUID')
    end
  end

end
