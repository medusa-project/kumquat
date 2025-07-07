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
# of elements that contained items are supposed to have.
#
# Collections also have a {PackageProfile}, which defines how collection
# content is structured in Medusa in terms of its file/directory layout, which
# in turn influences the kinds of {Item}s it contains.
#
# Collections are searchable via ActiveRecord as well as via OpenSearch (see
# below).
#
# # Representations
#
# See [Representable].
#
# # Indexing
#
# Instances are automatically indexed in ES (see {as_indexed_json}) in an
# `after_commit` callback. A low-level interface to OpenSearch is provided by
# OpensearchClient, but in most cases, it's better to use the higher-level
# query interface provided by {CollectionRelation}, which is easier to use, and
# takes authorization, public visibility, etc. into account. (An instance can
# be obtained from {search}.)
#
# **IMPORTANT**: Instances are automatically indexed in OpenSearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed on save.
# For this reason, **instances should always be created, updated, and deleted
# within transactions.**
#
# # Attributes
#
# * `access_systems`                Access systems through which the collection
#                                   is accessible. Copied from Medusa.
# * `access_url`                    URL at which the collection's contents are
#                                   available, for collections whose content
#                                   resides outside the DLS.
# * `contentdm_alias`               String alias of collections that have been
#                                   migrated out of CONTENTdm, used for URL
#                                   redirection.
# * `created_at`                    Managed by ActiveRecord.
# * `description_html`              HTML-formatted description, copied from
#                                   Medusa. N.B.: There may also be a
#                                   description element in the {elements} text
#                                   description, also copied from Medusa.
# * `descriptive_element_id`        ID of a [MetadataProfileElement] whose
#                                   values are used in the description boxes in
#                                   results view.
# * `external_id                    Value of the Medusa "external ID" field.
# * `harvestable                    Controls visibility of the collection's
#                                   contents in the generic OAI-PMH harvesting
#                                   endpoint. (See [OaiPmhController].)
# * `harvestable_by_idhh            Controls visibility of the collection's
#                                   contents in the IDHH OAI-PMH harvesting
#                                   endpoint. (See [OaiPmhController].)
# * `harvestable_by_primo           Controls visibility of the collection's
#                                   contents in the Primo OAI-PMH endpoint.
#                                   (See [OaiPmhController].)
# * `medusa_directory_uuid`         Medusa UUID of the root directory in which
#                                   the collection's contents reside. If nil,
#                                   the root directory of the file group will
#                                   be used.
# * `medusa_file_group_uuid`        Medusa UUID of the file group in which the
#                                   collection's contents reside.
# * `medusa_repository_id`
# * `metadata_profile_id`           Database ID of the [MetadataProfile]
#                                   assigned to the instance.
# * `package_profile_id`            ID of the [PackageProfile] assigned to the
#                                   collection. The content in the effective
#                                   root directory of the collection must
#                                   conform to this profile.
# * `physical_collection_url`       URL of the collection's archival collection
#                                   counterpart.
# * `public_in_medusa`              Whether the access level of the
#                                   collection's metadata is set to "public."
#                                   This and {published_in_dls} must be true in
#                                   order for the collection or any or any of
#                                   its items to be publicly accessible.
# * `publicize_binaries`            Whether binaries attached to items residing
#                                   in the collection are public. If set to
#                                   `true`, a binary may be made private by
#                                   setting its {Binary#public} property to
#                                   `false`, but if set to `false`, that
#                                   property is ignored.
# * `published_in_dls`              Whether the collection's content resides in
#                                   the DLS, or somewhere else.
#                                   N.B.: use {publicly_accessible?()} to test
#                                   a collection's effective public
#                                   accessibility.
# * `repository_id`                 The collection's effective UUID, copied
#                                   from Medusa.
# * `representation_type`           Enum field containing one of the
#                                   [Representation::Type] constant values.
# * `representative_image`          Filename of a representative image within
#                                   the application S3 bucket. See note about
#                                   representations above.
# * `representative_medusa_file_id` UUID of a Medusa image file representing
#                                   the collection. See note about
#                                   representations above.
# * `representative_item_id`        Repository ID of an [Item] representing the
#                                   collection. See note about representative
#                                   images above.
# * `resource_types`                Serialized array of resource types
#                                   contained within the collection, copied
#                                   from Medusa.
# * `restricted`                    Indicates a collection for which all items
#                                   are "private"--not discoverable in any way
#                                   and restricted to a particular NetID.
#                                   (DLD-337)
# * `rights_statement`              Rights statement text.
# * `rights_term_uri`               URI of a term in one of the rights-related
#                                   vocabularies.
# * `supplementary_document_label`  Label of the supplementary document section
#                                   for items in the collection that have such
#                                   documents.
# * `updated_at`                    Managed by ActiveRecord.
#
# Attribute Propagation
#
# Changes to some of a collection's properties, such as {allowed_host_groups},
# must be propagated to all of its [Item]s. This can be done using
# {propagate_heritable_properties}.
#
class Collection < ApplicationRecord

  include AuthorizableByHost
  include Describable
  include Indexed
  include Representable

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    ACCESS_SYSTEMS                     = 'sys_k_access_systems'
    ACCESS_URL                         = 'sys_k_access_url'
    ALLOWED_HOST_GROUP_COUNT           = 'sys_i_allowed_host_group_count'
    ALLOWED_HOST_GROUPS                = 'sys_k_allowed_host_groups'
    CLASS                              = OpensearchIndex::StandardFields::CLASS
    DESCRIPTION                        = CollectionElement.new(name: 'description').indexed_field
    EFFECTIVE_ALLOWED_HOST_GROUP_COUNT = 'sys_i_effective_allowed_host_group_count'
    EFFECTIVE_ALLOWED_HOST_GROUPS      = 'sys_k_effective_allowed_host_groups'
    EXTERNAL_ID                        = 'sys_k_external_id'
    HARVESTABLE                        = 'sys_b_harvestable'
    HARVESTABLE_BY_IDHH                = 'sys_b_harvestable_by_idhh'
    HARVESTABLE_BY_PRIMO               = 'sys_b_harvestable_by_primo'
    LAST_INDEXED                       = OpensearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED                      = OpensearchIndex::StandardFields::LAST_MODIFIED
    NATIVE                             = 'sys_b_native'
    PARENT_COLLECTIONS                 = 'sys_k_parent_collections'
    PUBLIC_IN_MEDUSA                   = 'sys_b_public_in_medusa'
    PUBLICLY_ACCESSIBLE                = OpensearchIndex::StandardFields::PUBLICLY_ACCESSIBLE
    PUBLISHED_IN_DLS                   = 'sys_b_published_in_dls'
    REPOSITORY_ID                      = 'sys_k_repository_id'
    REPOSITORY_TITLE                   = 'sys_k_repository_title'
    REPRESENTATIVE_ITEM                = 'sys_k_representative_item'
    RESOURCE_TYPES                     = 'sys_k_resource_types'
    RESTRICTED                         = OpensearchIndex::StandardFields::RESTRICTED
    SEARCH_ALL                         = OpensearchIndex::StandardFields::SEARCH_ALL
    TITLE                              = CollectionElement.new(name: 'title').indexed_field
  end

  LOGGER = CustomLogger.new(Collection)

  serialize :access_systems, coder: JSON
  serialize :resource_types, coder: JSON

  belongs_to :descriptive_element, class_name: 'MetadataProfileElement',
             optional: true
  belongs_to :metadata_profile, inverse_of: :collections,
             optional: true

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
  has_many :watches

  has_and_belongs_to_many :allowed_host_groups, class_name: 'HostGroup',
                          association_foreign_key: :allowed_host_group_id

  validates_format_of :repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid'
  validates :representation_type, inclusion: { in: Representation::Type.all },
            allow_blank: true
  validate :validate_representative_image_format
  validate :validate_medusa_uuids

  before_validation :do_before_validation

  # In the order they should appear in the TSV, left-to-right. These generally
  # correspond to database columns although they need not be named the same.
  TSV_COLUMNS = %w(uuid title description publicInMedusa publishedInDLS
    restricted publicizeBinaries representativeItemID
    representativeMedusaFileID medusaRepositoryID medusaFileGroupUUID
    medusaDirectoryUUID packageProfile physicalCollectionURI externalID
    accessURI rightsStatement rightsTermURI harvestable harvestableByIDHH
harvestableByPrimo)

  # This is commented out because, even though it has to happen, it is
  # potentially very time-consuming. CollectionsController.update() is
  # currently the only means by which collections are updated, so it will
  # invoke this method in a background task.
  #
  #after_update :propagate_host_authorization

  ##
  # @return [Enumerable<Hash>] Array of hashes with `:name`, `:label`, and `id`
  #                            keys in the order they should appear.
  #
  def self.facet_fields
    [
      {
        name:  CollectionElement.new(name: IndexFields::REPOSITORY_TITLE).indexed_keyword_field,
        label: 'Repository',
        id:    'dl-repository-facet'
      },
      {
        name:  CollectionElement.new(name: IndexFields::RESOURCE_TYPES).indexed_keyword_field,
        label: 'Resource Type',
        id:    'dl-resource-type-facet'
      },
      {
        name:  CollectionElement.new(name: IndexFields::ACCESS_SYSTEMS).indexed_keyword_field,
        label: 'Access Systems',
        id:    'dl-access-systems-facet'
      }
    ]
  end

  ##
  # @param id [String] Medusa collection ID.
  # @return [Collection]
  #
  def self.from_medusa(id)
    col = Collection.new
    col.repository_id = id
    col.update_from_medusa
    col
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
    result = OpensearchClient.instance.query(json)
    struct = JSON.parse(result)
    struct['hits']['hits'].map{ |r| r['_source'][Item::IndexFields::REPOSITORY_ID] }
  end

  ##
  # @return [Hash] Harvestable representation. This does not include any links
  #                (URLs).
  #
  def as_harvestable_json
    access_master_struct = nil
    rep                 = self.effective_file_representation
    case rep.type
    when Representation::Type::MEDUSA_FILE
      if rep.file
        begin
          access_master_struct = {
            id:         rep.file.uuid,
            object_uri: "s3://#{MedusaS3Client::BUCKET}/#{rep.file.relative_key}",
            media_type: rep.file.media_type
          }
        rescue Medusa::NotFoundError => e
          LOGGER.warn("Collection.as_harvestable_json(): file not found in medusa: #{e}")
        end
      end
    when Representation::Type::LOCAL_FILE
      access_master_struct = {
        object_uri: "s3://#{KumquatS3Client::BUCKET}/#{rep.key}"
      }
    end
    {
        class:                   self.class.to_s,
        id:                      self.repository_id,
        external_id:             self.external_id,
        access_uri:              self.access_url,
        physical_collection_uri: self.physical_collection_url,
        repository_title:        self.medusa_repository.title,
        resource_types:          self.resource_types,
        access_systems:          self.access_systems,
        package_profile:         self.package_profile&.name,
        access_master_image:     access_master_struct,
        elements:                self.elements_in_profile_order(only_visible: true)
                                     .map{ |e| { name: e.name, value: e.value } },
        created_at:              self.created_at,
        updated_at:              self.updated_at
    }
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::ACCESS_SYSTEMS]           = self.access_systems
    doc[IndexFields::ACCESS_URL]               = self.access_url
    doc[IndexFields::ALLOWED_HOST_GROUPS]      = self.allowed_host_groups.pluck(:key)
    doc[IndexFields::ALLOWED_HOST_GROUP_COUNT] =
        doc[IndexFields::ALLOWED_HOST_GROUPS].length
    doc[IndexFields::CLASS]                    = self.class.to_s
    doc[IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS] =
        doc[IndexFields::ALLOWED_HOST_GROUPS]
    doc[IndexFields::EFFECTIVE_ALLOWED_HOST_GROUP_COUNT] =
        doc[IndexFields::ALLOWED_HOST_GROUP_COUNT]
    doc[IndexFields::EXTERNAL_ID]          = self.external_id
    doc[IndexFields::HARVESTABLE]          = self.harvestable
    doc[IndexFields::HARVESTABLE_BY_IDHH]  = self.harvestable_by_idhh
    doc[IndexFields::HARVESTABLE_BY_PRIMO] = self.harvestable_by_primo
    doc[IndexFields::LAST_INDEXED]         = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]        = self.updated_at.utc.iso8601
    doc[IndexFields::NATIVE]               = self.package_profile_id.present?
    doc[IndexFields::PARENT_COLLECTIONS]   =
        self.parent_collection_joins.pluck(:parent_repository_id)
    doc[IndexFields::PUBLIC_IN_MEDUSA]     = self.public_in_medusa
    doc[IndexFields::PUBLICLY_ACCESSIBLE]  = self.publicly_accessible?
    doc[IndexFields::PUBLISHED_IN_DLS]     = self.published_in_dls
    doc[IndexFields::REPOSITORY_ID]        = self.repository_id
    doc[IndexFields::REPOSITORY_TITLE]     = self.medusa_repository&.title
    doc[IndexFields::REPRESENTATIVE_ITEM]  = self.representative_item_id
    doc[IndexFields::RESOURCE_TYPES]       = self.resource_types
    doc[IndexFields::RESTRICTED]           = self.restricted

    self.elements.each do |element|
      # Skip non-indexable elements. Elements are considered indexable if they
      # are marked as indexed in the collection's metadata profile, or if the
      # collection doesn't have a metadata profile.
      next unless (!self.metadata_profile or self.metadata_profile.elements.
        find{ |mpe| mpe.name == element.name }&.indexed)

      unless doc[element.indexed_field]&.respond_to?(:each)
        doc[element.indexed_field] = []
      end
      doc[element.indexed_field] <<
          StringUtils.strip_leading_articles(element.value)[0..OpensearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  ##
  # Satisfies the AuthorizableByHost module contract.
  #
  alias_method :effective_allowed_host_groups, :allowed_host_groups

  ##
  # Deletes indexed documents whose corresponding Items no longer exist in the
  # database.
  #
  def delete_orphaned_item_documents
    item_ids     = all_indexed_item_ids
    count        = item_ids.length
    progress     = Progress.new(count)
    orphaned_ids = []

    item_ids.each_with_index do |id, index|
      unless Item.find_by_repository_id(id)
        orphaned_ids << id
      end
      progress.report(index, 'Finding orphaned documents')
    end

    if orphaned_ids.any?
      query = Jbuilder.encode do |j|
        j.query do
          j.terms do
            j.set! Item::IndexFields::REPOSITORY_ID, orphaned_ids
          end
        end
      end
      OpensearchClient.instance.delete_by_query(query)
    end
  end

  ##
  # Overrides the same method in [Representable].
  #
  def effective_file_representation
    rep = effective_representation
    if rep.type == Representation::Type::ITEM && rep.item
      rep = rep.item.effective_file_representation
    end
    rep
  end

  ##
  # The effective CFS directory of the instance -- either one that is directly
  # assigned, or the root CFS directory of the file group.
  #
  # @return [Medusa::Directory, nil]
  # @see medusa_directory
  #
  def effective_medusa_directory
    self.medusa_directory || self.medusa_file_group&.directory
  end

  ##
  # @return [MetadataProfile] The profile assigned to the instance, or the
  #                           default profile if none is assigned.
  #
  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  ##
  # Overrides the same method in [Representable].
  #
  # @return [Representation]
  #
  def effective_representation
    rep = Representation.new
    rep.type = self[:representation_type]

    case self.representation_type
    when Representation::Type::LOCAL_FILE
      rep.key = self.representative_image_key_prefix + self.representative_image
    when Representation::Type::MEDUSA_FILE
      begin
        rep.file = self.representative_medusa_file
      rescue => e
        LOGGER.warn('%s(): %s', __method__, e)
      end
    when Representation::Type::ITEM
      rep.item = self.representative_item
    else
      rep.type       = Representation::Type::COLLECTION
      rep.collection = self
    end
    rep
  end

  ##
  # @param only_visible [Boolean]
  # @return [Enumerable<CollectionElement>] The instance's [CollectionElement
  #         metadata elements] in the order of the elements in the instance's
  #         metadata profile. If there is no associated metadata profile, all
  #         elements are returned.
  #
  def elements_in_profile_order(only_visible: false)
    elements = []
    profile  = self.metadata_profile
    if profile
      mp_elements = profile.elements
      mp_elements = mp_elements.where(visible: true) if only_visible
      mp_elements.each do |mpe|
        element   = self.element(mpe.name)
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
  # The Medusa directory in which content resides. This may be the same as the
  # root directory of the file group, or deeper within it. This is used as a
  # refinement of {medusa_file_group}.
  #
  # @return [Medusa::Directory, nil]
  # @see effective_medusa_directory
  #
  def medusa_directory
    unless @medusa_directory
      @medusa_directory = nil
      if self.medusa_directory_uuid.present?
        @medusa_directory = Medusa::Directory.with_uuid(self.medusa_directory_uuid)
      end
    end
    @medusa_directory
  end

  ##
  # @return [Medusa::FileGroup]
  #
  def medusa_file_group
   unless @file_group
     @file_group = nil
     if self.medusa_file_group_uuid.present?
       @file_group = Medusa::FileGroup.with_uuid(self.medusa_file_group_uuid)
     end
   end
   @file_group
  end

  ##
  # @return [Medusa::Repository]
  #
  def medusa_repository
    unless @medusa_repository
      @medusa_repository = nil
      if self.medusa_repository_id.present?
        @medusa_repository = Medusa::Repository.with_id(self.medusa_repository_id)
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
      @num_items = Item.search.
          collection(self).
          aggregations(false).
          search_children(true).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
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
      relation = Item.search.
          collection(self).
          aggregations(false).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
          order(false).
          limit(0)
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_objects = relation.
              include_variants(*Item::Variants::FILE).
              include_children_in_results(true).
              count
        else
          @num_objects = relation.search_children(false).count
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
          @num_public_objects = Item.search.
              collection(self).
              aggregations(false).
              include_variants(*Item::Variants::FILE).
              include_children_in_results(true).
              count
        else
          @num_public_objects = Item.search.
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
  # Propagates allowed {HostGroup}s from the instance to all of its items. This
  # is an O(n) operation.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_heritable_properties(task = nil)
    num_items = self.items.count
    Item.uncached do
      self.items.find_each.with_index do |item, index|
        transaction do
          item.save!
        end
        if task && index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Boolean] The instance's effective public accessibility status.
  #
  def publicly_accessible?
    public_in_medusa && (published_in_dls || access_url.present?)
  end

  ##
  # Deletes all items in the collection. Does not refresh the index.
  #
  # @return [Integer] Number of items purged.
  #
  def purge
    items = self.items
    count = items.count
    transaction do
      items.destroy_all
    end
    count
  end

  def reindex_items
    # Reindex all database items.
    puts "Step 1/2"
    items    = Item.where(collection_repository_id: self.repository_id)
    count    = items.count
    progress = Progress.new(count)
    items.each_with_index do |item, index|
      item.reindex
      progress.report(index, 'Reindexing collection items')
    end

    # Delete indexed documents of items no longer present in the database.
    puts "Step 2/2"
    delete_orphaned_item_documents
  end

  ##
  # @return [Medusa::Repository]
  #
  def repository
    if medusa_repository_id.present?
      Medusa::Repository.with_id(self.medusa_repository_id)
    end
  end

  ##
  # @return [VocabularyTerm, nil]
  #
  def rights_term
    VocabularyTerm.find_by_uri(self.rights_term_uri)
  end

  ##
  # @return [Item, nil] If the instance is free-form and uses a subdirectory
  #                     within a file group, that corresponding {Item}.
  #                     Otherwise, nil.
  #
  def root_item
    if free_form? and medusa_directory_uuid.present?
      return Item.where(collection_repository_id: self.repository_id)
                 .where(parent_repository_id: nil)
                 .limit(1)
                 .first
    end
    nil
  end

  ##
  # @return [Integer] Total number of items across subcollections (parent collection's children collections)
  #                   
  def subcollections_public_items_count
    children.sum(&:num_public_objects)
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
    client   = Medusa::Client.instance
    response = client.get(self.medusa_url('json'))
    if response.status == 200
      json_str = response.body
      struct   = JSON.parse(json_str)
    else
      raise ActiveRecord::RecordNotFound
    end

    transaction do
      self.elements.destroy_all

      self.access_systems          = struct['access_systems'].map{ |t| t['name'] }
      self.access_url              = struct['access_url']
      if struct['description'].present?
        self.elements.build(name:  'description',
                            value: struct['description'])
      end
      self.description_html        = struct['description_html']
      self.external_id             = struct['external_id']
      self.medusa_repository_id    = struct['repository_path'].gsub(/[^\d+]/, '').to_i
      self.physical_collection_url = struct['physical_collection_url']
      self.public_in_medusa        = struct['publish']
      self.resource_types          = struct['resource_types'].map do |t| # titleize these
        t['name'].split(' ').map{ |t| t.present? ? t.capitalize : '' }.join(' ')
      end
      self.rights_statement        = struct['rights']['custom_copyright_statement']
      self.elements.build(name:  'title',
                          value: struct['title'])

      self.save!

      # Create relationships (CollectionJoins) to other collections. Note that
      # some of these save commands will fail the first time this method is
      # invoked, since not all collections have been created yet. They should
      # succeed on all later invocations.
      self.parent_collection_joins.destroy_all
      struct['parent_collections'].each do |parent_struct|
        begin
          self.parent_collection_joins.build(parent_repository_id: parent_struct['uuid'],
                                             child_repository_id:  self.repository_id).save!
        rescue ActiveRecord::RecordInvalid
          puts "Unable to relate parent #{parent_struct['uuid']} to child "\
                 "#{self.repository_id} -- if this is the first time this "\
                 "command has ever been run, this is not a problem."
        end
      end
      self.child_collection_joins.destroy_all
      struct['child_collections'].each do |child_struct|
        begin
          self.child_collection_joins.build(parent_repository_id: self.repository_id,
                                            child_repository_id:  child_struct['uuid']).save!
        rescue ActiveRecord::RecordInvalid
          puts "Unable to relate parent #{self.repository_id} to child "\
                 "#{child_struct['uuid']} -- if this is the first time this "\
                 "command has ever been run, this is not a problem."
        end
      end
    end
  end


  private

  def do_before_validation
    self.medusa_directory_uuid&.strip!
    self.medusa_file_group_uuid&.strip!
    self.representative_medusa_file_id&.strip!
    self.representative_item_id&.strip!
  end

  ##
  # Overrides the same method in [Representable].
  #
  def representative_image_key_prefix
    "representative_images/collection/#{repository_id}/"
  end

  def validate_medusa_uuids
    client = Medusa::Client.instance
    if self.medusa_file_group_uuid.present? &&
      self.medusa_file_group_uuid_changed? &&
        client.class_of_uuid(self.medusa_file_group_uuid) != Medusa::FileGroup
      errors.add(:medusa_file_group_uuid, 'is not a Medusa file group UUID')
    end
    if self.medusa_directory_uuid.present? &&
        self.medusa_directory_uuid_changed? &&
        client.class_of_uuid(self.medusa_directory_uuid) != Medusa::Directory
      errors.add(:medusa_directory_uuid, 'is not a Medusa directory UUID')
    end
  end

  def validate_representative_image_format
    if self.representative_image.present?
      unless Representation::SUPPORTED_IMAGE_FORMATS.include?(self.representative_image.split(".").last)
        errors.add(:representative_image, "is of an unsupported format")
      end
    end
  end

end
