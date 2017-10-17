##
# Encapsulates a Medusa collection.
#
# Collections are identified by their repository ID (`repository_id`), which
# is a UUID matching a collection's Medusa UUID.
#
# Collections can "contain" zero or more items. (This is a weak relationship;
# the collections don't literally contain them, but items maintain a reference
# to their owning collection's repository ID.)
#
# Collections are associated with a metadata profile, which defines the list
# of elements that contained items are supposed to have, as well as a package
# profile, which defines how collection content is structured in Medusa in
# terms of its file/directory layout.
#
# Collections are searchable via ActiveRecord as well as via Elasticsearch.
# Instances are automatically indexed in ES (see `as_indexed_json()`) in an
# after_commit callback, and the ES search functionality is available
# via the `search` class method. A higher-level CollectionFinder is also
# available.
#
# # Attributes
#
# * access_systems:           Access systems through which the collection is
#                             accessible. Copied from Medusa.
# * access_url:               URL at which the collection's contents are
#                             available, for collections whose content resides
#                             outside the DLS.
# * contentdm_alias:          String alias of collections that have been
#                             migrated out of CONTENTdm, used for URL
#                             redirection.
# * created_at:               Managed by ActiveRecord.
# * description_html:         HTML-formatted description, copied from Medusa.
#                             N.B. There may also be a description element in
#                             the `elements` relationship containing a plain
#                             text description, also copied from Medusa.
# * external_id:              Value of the Medusa "external ID" field.
# * harvestable:              Controls visiblity of the collection's contents
#                             in the OAI-PMH (or whatever) harvesting
#                             endpoints.
# * medusa_cfs_directory_id:  Medusa UUID of the root directory in which the
#                             collection's contents reside. If nil, the root
#                             directory of the file group will be used.
# * medusa_file_group_id:     Medusa UUID of the file group in which the
#                             collection's contents reside.
# * medusa_repository_id:
# * metadata_profile_id:      Database ID of the MetadataProfile assigned to
#                             the collection.
# * package_profile_id:       ID of the PackageProfile assigned to the
#                             collection. The content in the effective root
#                             directory of the collection must conform to this
#                             profile.
# * physical_collection_url:  URL of the collection's archival collection
#                             counterpart.
# * public_in_medusa:         Whether the access level of the collection's
#                             metadata is set to "public." This and
#                             `published_in_dls` must be true in order for the
#                             collection or any or any of its items to be
#                             publicly accessible.
# * published_in_dls:         "Published" status of the collection in the DLS.
#                             N.B. use `published()` to test a collection's
#                             effective "published" status.
# * repository_id:            The collection's effective UUID, copied from
#                             Medusa.
# * representative_image:     UUID of a Medusa image file representing the
#                             collection for use in e.g. thumbnails.
#                             `representative_item_id` should be used instead,
#                             if possible.
# * representative_item_id:   Repository ID of an Item representating the
#                             collection for use in e.g. thumbnails.
# * resource_types:           Serialized array of resource types contained
#                             within the collection, copied from Medusa.
# * rights_statement:         Rights statement text.
#                             TODO: store this in an accessRights CollectionElement
# * rightsstatements_org_uri: URI of a RightsStatements.org statement.
#                             TODO: store this in an accessRights CollectionElement
# * updated_at:               Managed by ActiveRecord.
#
# @see https://github.com/elastic/elasticsearch-rails/blob/master/elasticsearch-model/README.md
#
class Collection < ApplicationRecord

  include AuthorizableByRole
  include Describable
  include Elasticsearch::Model
  include Representable

  class IndexFields
    ACCESS_SYSTEMS = 'access_systems'
    ACCESS_URL = 'access_url'
    ALLOWED_ROLES = 'allowed_roles'
    DENIED_ROLES = 'denied_roles'
    DESCRIPTION = CollectionElement.new(name: 'description').indexed_field
    # Contains the result of PUBLIC_IN_DLS && PUBLISHED_IN_MEDUSA.
    EFFECTIVELY_PUBLISHED = 'effectively_published'
    EXTERNAL_ID = 'external_id'
    HARVESTABLE = 'harvestable'
    LAST_INDEXED = 'date_last_indexed'
    PARENT_COLLECTIONS = 'parent_collections'
    PUBLIC_IN_MEDUSA = 'public_in_medusa'
    PUBLISHED_IN_DLS = 'published_in_dls'
    REPOSITORY_ID = 'repository_id'
    REPOSITORY_TITLE = 'repository_title'
    REPRESENTATIVE_IMAGE = 'representative_image'
    REPRESENTATIVE_ITEM = 'representative_item'
    RESOURCE_TYPES = 'resource_types'
    SEARCH_ALL = '_all'
    TITLE = CollectionElement.new(name: 'title').indexed_keyword_field
  end

  serialize :access_systems
  serialize :resource_types

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
  # invoke this method in a background job.
  #
  #after_update :propagate_host_authorization

  after_commit :index_in_elasticsearch, on: [:create, :update]
  after_commit :delete_from_elasticsearch, on: :destroy

  # Used by the Elasticsearch client for CRUD actions only (not index changes).
  index_name ElasticsearchIndex.current_index(self).name

  ##
  # @return [Enumerable<Hash>] Array of hashes with `:name`, `:label`, and `id`
  #                            keys in the order they should appear.
  #
  def self.facet_fields
    [
        { name: IndexFields::REPOSITORY_TITLE, label: 'Repository',
          id: 'pt-repository-facet' },
        { name: IndexFields::RESOURCE_TYPES, label: 'Resource Type',
          id: 'pt-resource-type-facet' },
        { name: IndexFields::ACCESS_SYSTEMS, label: 'Access Systems',
          id: 'pt-access-systems-facet' }
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
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def self.reindex_all(index = :current)
    Collection.uncached do
      count = Collection.count
      Collection.all.find_each.with_index do |col, i|
        col.reindex(index)

        pct_complete = (i / count.to_f) * 100
        CustomLogger.instance.debug("Collection.reindex_all(): #{pct_complete.round(2)}%")
      end
      # Remove indexed documents whose entities have disappeared.
      # TODO: fix this
      #Collection.solr.all.limit(99999).select{ |c| c.to_s == c }.each do |col_id|
      #  Solr.delete_by_id(col_id)
      #end
    end
  end

  ##
  # N.B.: Changing this normally requires adding a new index schema version.
  #
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json(options = {})
    doc = {}
    doc[IndexFields::ACCESS_SYSTEMS] = self.access_systems
    doc[IndexFields::ACCESS_URL] = self.access_url
    doc[IndexFields::ALLOWED_ROLES] = self.allowed_roles.pluck(:key)
    doc[IndexFields::DENIED_ROLES] = self.denied_roles.pluck(:key)
    doc[IndexFields::EFFECTIVELY_PUBLISHED] = self.published
    doc[IndexFields::EXTERNAL_ID] = self.external_id
    doc[IndexFields::HARVESTABLE] = self.harvestable
    doc[IndexFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[IndexFields::PARENT_COLLECTIONS] =
        self.parent_collection_joins.pluck(:parent_repository_id)
    doc[IndexFields::PUBLIC_IN_MEDUSA] = self.public_in_medusa
    doc[IndexFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[IndexFields::REPOSITORY_ID] = self.repository_id
    doc[IndexFields::REPOSITORY_TITLE] = self.medusa_repository&.title
    doc[IndexFields::REPRESENTATIVE_ITEM] = self.representative_item_id
    doc[IndexFields::RESOURCE_TYPES] = self.resource_types

    self.elements.each do |element|
      # ES will automatically create a one or more multi fields for this.
      # See: https://www.elastic.co/guide/en/elasticsearch/reference/0.90/mapping-multi-field-type.html
      doc[element.indexed_field] = element.value
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
  # @see representative_image_binary()
  #
  def effective_representative_image_binary
    bin = self.representative_item&.iiif_image_binary
    unless bin
      begin
        bin = self.representative_image_binary
      rescue => e
        CustomLogger.instance.warn(
            "Collection.effective_representative_image_binary(): #{e}")
      end
    end
    bin
  end

  ##
  # @return [Item, nil] Item that effectively represents the instance.
  # @see representative_item()
  #
  def effective_representative_item
    item = self.representative_item
    unless item
      begin
        item = self.representative_image_binary&.item
      rescue => e
        CustomLogger.instance.warn(
            "Collection.effective_representative_item(): #{e}")
      end
    end
    item
  end

  ##
  # @return [Boolean]
  #
  def free_form?
    self.package_profile_id == PackageProfile::FREE_FORM_PROFILE.id
  end

  ##
  # @return [Enumerable<Set>]
  # @return [ActiveRecord::Relation<Item>] All items in the collection.
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
  # as a refinement of medusa_file_group.
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
  # @return [Integer] Number of items in the collection regardless of hierarchy
  #                   level or public accessibility. The result is cached.
  #
  def num_items
    unless @num_items
      @num_items = ItemFinder.new.
          collection(self).
          search_children(true).
          include_unpublished(true).
          only_described(false).
          limit(0).
          count
    end
    @num_items
  end

  ##
  # @return [Integer] Number of objects in the collection. The result is cached.
  #
  def num_objects
    unless @num__objects
      case self.package_profile
        when PackageProfile::FREE_FORM_PROFILE
          @num_objects = ItemFinder.new.
              collection(self).
              only_described(false).
              include_unpublished(true).
              include_variants(*Item::Variants::FILE).
              count
        else
          @num_objects = ItemFinder.new.
              collection(self).
              only_described(false).
              include_unpublished(true).
              search_children(false).
              count
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
              only_described(true).
              include_variants(*Item::Variants::FILE).
              count
        else
          @num_public_objects = ItemFinder.new.
              collection(self).
              only_described(true).
              search_children(false).
              count
      end
    end
    @num_public_objects
  end

  ##
  # @return [PackageProfile,nil]
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
      # after_save callbacks will call this method on direct children, so there
      # is no need to crawl deeper levels of the item tree.
      num_items = self.items.count
      self.items.where(parent_repository_id: nil).each_with_index do |item, index|
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Boolean] The instance's effective "published" status.
  #
  def published
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
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def reindex(index = :current)
    index_in_elasticsearch(index)
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
        cfs_file = MedusaCfsFile.with_uuid(self.representative_image)
        binary = cfs_file.to_binary(Binary::MasterType::ACCESS)
      end
    end
    binary
  end

  ##
  # @return [Item, nil] Item assigned to represent the instance. May be nil.
  # @see effective_representative_item()
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
    logger = CustomLogger.instance
    begin
      logger.debug(['Deleting document... ',
                    __elasticsearch__.delete_document].join)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      logger.warn("Collection.delete_from_elasticsearch(): #{e}")
    end
  end

  def do_before_validation
    self.medusa_cfs_directory_id&.strip!
    self.medusa_file_group_id&.strip!
    self.representative_image&.strip!
    self.representative_item_id&.strip!
  end

  ##
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def index_in_elasticsearch(index = :current)
    ElasticsearchClient.instance.index_document(index,
                                                self.class,
                                                self.id,
                                                as_indexed_json)
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
