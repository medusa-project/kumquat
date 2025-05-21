# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Structure
#
# All items reside in a [Collection]. An item may have one or more child items,
# as may any of those, forming a tree. The tree structure depends on the
# collection's [PackageProfile]. The {PackageProfile::FREE_FORM_PROFILE
# free-form profile} allows an arbitrary structure; other profiles are more
# rigid.
#
# An item may also have one or more [Binary binaries], each corresponding to a
# file in Medusa.
#
# # Variants
#
# There several different kinds of items:
#
# * A "compound object" is an item that has one or more child items not of
#   {Variants::FILE file} or {Item::Variants::DIRECTORY directory} variant. It
#   is found in collections that use the
#   {PackageProfile::COMPOUND_OBJECT_PROFILE compound object} or
#   {PackageProfile::MIXED_MEDIA_PROFILE mixed-media package profile}. It has
#   no assigned variant.
#     * Its child items always have a variant, which may be anything other than
#       {Item::Variants::FILE} or {Item::Variants::DIRECTORY}.
# * A "single-item object" is an item not of {Variants::FILE file} or
#   {Item::Variants::DIRECTORY directory} variant that has no children. It is
#   found in collections that use the
#   {PackageProfile::SINGLE_ITEM_OBJECT_PROFILE single-item object package
#   profile}. It has no assigned variant.
# * A "file item" is an item of {Variants::FILE file} variant. It always has
#   a {Item::Variants::DIRECTORY directory} parent, and no children. It is
#   found only in collections that use the {PackageProfile::FREE_FORM_PROFILE
#   free-form package profile}.
# * A "directory item" is an item of {Variants::DIRECTORY directory} variant.
#   It may have zero or more child items of either
#   {Item::Variants::DIRECTORY directory} or {Item::Variants::FILE file}
#   variant. It is found only in collections that use the
#   {PackageProfile::FREE_FORM_PROFILE free-form package profile}.
#
# # Identifiers
#
# Medusa is not item-aware; items are a DLS entity. Item IDs correspond to
# Medusa file/directory UUIDs depending on a collection's package profile.
# These IDs are stored in `repository_id`, **not** `id`, which is only used by
# ActiveRecord.
#
# Items have a soft pointer to their owning {Collection} and parent item based
# on repository ID, rather than a `belongs_to`/`has_many` on their database ID.
# This is in order to establish structure outside of the application.
# Repository IDs are the same in all instances of the application that use the
# same Medusa content.
#
# # Description
#
# Items have a number of properties of their own (see below) as well as a
# one-to-many relationship with {ItemElement}, which encapsulates a metadata
# element. The general distinction is that properties are used by the system,
# and {ItemElement}s are used for description.
#
# ## Properties
#
# ### Adding a property:
#
# 1. Add a column for it on Item
# 2. Add it to {IndexFields} (if it needs to be indexed)
# 3. Add serialization code to {as_json} and perhaps {as_indexed_json} and
#    {as_harvestable_json}
# 4. Add deserialization code to {update_from_json}
# 5. If it needs to appear in TSV, add it to {tsv_columns}, {ItemTsvExporter},
#    and/or {update_from_tsv}
# 6. Update fixtures and tests
# 7. Reindex (if necessary)
#
# ## Descriptive Metadata
#
# The set of elements that an item will contain is shaped by its collection's
# metadata profile, but there is no constraint in place to keep an item from
# being associated with elements not in the profile. This is a safety feature,
# so that deleting an element from a profile does not delete it from any items
# contained in the collections to which the profile is assigned.
#
# # Representations
#
# See [Representable].
#
# # Rights
#
# Rights information can be directly ascribed to an item by associating it with
# an element whose {EntityElement#uri} value matches one of the terms in its
# associated RightsStatements.org, Creative Commons, etc. [Vocabulary
# vocabularies]. If there is no such associated element value, one is drawn
# from a parent item, if one exists. Otherwise, the owning [Collection]'s
# {Collection#effective_rights_term} is used.
#
# It is also possible to ascribe a free-form rights statement. This is added to
# the string value of a `rights` element.
#
# # Indexing
#
# Items are searchable via ActiveRecord as well as via OpenSearch. A low-level
# interface to OpenSearch is provided by OpensearchClient, but in most cases,
# it's better to use the higher-level query interface provided by
# {ItemRelation}, which is easier to use, and takes authorization, public
# visibility, etc. into account. (An instance of {ItemRelation} can be obtained
# from {search}.)
#
# **IMPORTANT**: Instances are automatically indexed in OpenSearch (see
# `as_indexed_json()`) upon transaction commit. They are **not** indexed on
# save. For this reason, **instances should always be created, updated, and
# deleted within transactions.**
#
# # Sorting
#
# The indexed document contains a {IndexFields::STRUCTURAL_SORT} key that
# assists in sorting item documents retrieved from OpenSearch by their
# structure. For example, for a compound object, the {Variants::FRONT_COVER
# front cover} will appear first, then the {Variants::PAGE pages} in page
# order, then the {Variants::BACK_COVER back cover}.
#
# # Attributes
#
# * `allowed_netids`                Serialized array of hashes with `netid`
#                                   and `expires` keys. The latter is an epoch
#                                   second. This array contains the NetID(s) of
#                                   the user(s) allowed to access the item,
#                                   alongside the times that this access
#                                   expires. (This supports the temporary
#                                   "Restricted Access" feature [DLD-337]. For
#                                   most items, it is null or empty.)
# * `collection_repository_id`      See "Identifiers" above.
# * `contentdm_alias`               String collection alias of items that have
#                                   been migrated out of CONTENTdm, used for
#                                   URL redirection.
# * `contentdm_pointer`             Integer "pointer" (in CONTENTdm lingo) of
#                                   items that have been migrated out of
#                                   CONTENTdm, used for URL redirection.
# * `created_at`                    Managed by ActiveRecord.
# * `start_date`                    Start date of a normalized date range.
# * `embed_tag`                     HTML snippet that will be used to display
#                                   an alternative object viewer.
# * `end_date`                      End date of a normalized date range.
# * `expose_full_text_search`       Whether to expose full-text search of the
#                                   instance and any child items on the public
#                                   website. (This only has an effect when full
#                                   text is present.)
# * `latitude`                      Normalized latitude in decimal degrees.
# * `longitude`                     Normalized longitude in decimal degrees.
# * `ocred`                         Whether item(s) have been run through OCR. Default
#                                   is `false`. 
# * `page_number`                   Literal page number of a page-variant item.
# * `parent_repository_id`          See "Identifiers" above.
# * `published`                     Controls public availability. Unpublished
#                                   items shouldn't appear in public search
#                                   results or be accessible in any other way
#                                   publicly.
# * `published_at`                  Date/time that the item was first
#                                   published. For free-form items, this is the
#                                   time that the {published} attribute was set
#                                   to `true`. For all other items, it is the
#                                   first time that a metadata element other
#                                   than `title` was ascribed. This is set by
#                                   an ActiveRecord callback.
# * `repository_id`                 See "Identifiers" above.
# * `representation_type`           Enum field containing one of the
#                                   [Representation::Type] constant values.
# * `representative_image`          Filename of a representative image within
#                                   the application S3 bucket. See note about
#                                   representations above.
# * `representative_item_id`        Dummy column used to comply with
#                                   [Representable].
# * `representative_medusa_file_id` UUID of an alternative Medusa file
#                                   designated to stand in as a representation
#                                   of the item.
# * `subpage_number`                Subpage number of a page-variant item. Only
#                                   used when there are multiple items
#                                   corresponding to a single page of a
#                                   physical object.
# * `updated_at`                    Managed by ActiveRecord.
# * `variant`                       Like a subclass. Used to differentiate
#                                   types of items. The only items without a
#                                   variant are "compound objects", or parent
#                                   items with non-file/directory-variant child
#                                   items.
#
# ## Attribute Propagation
#
# Some item properties, such as {allowed_hosts}, propagate to child items in
# the item tree. The inherited counterparts of these properties are
# {effective_allowed_hosts}. An item's subtree can be updated using
# {propagate_heritable_properties}.
#
class Item < ApplicationRecord

  include AuthorizableByHost
  include Describable
  include Indexed
  include Representable

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    CLASS                              = OpensearchIndex::StandardFields::CLASS
    COLLECTION                         = 'sys_k_collection'
    CREATED                            = 'sys_d_created'
    DATE                               = 'sys_d_date'
    DESCRIBED                          = 'sys_b_described'
    EFFECTIVE_ALLOWED_HOST_GROUP_COUNT = 'sys_i_effective_allowed_host_group_count'
    EFFECTIVE_ALLOWED_HOST_GROUPS      = 'sys_k_effective_allowed_host_groups'
    FULL_TEXT                          = 'sys_t_full_text'
    ITEM_SETS                          = 'sys_i_item_sets'
    LAST_INDEXED                       = OpensearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED                      = OpensearchIndex::StandardFields::LAST_MODIFIED
    LAT_LONG                           = 'sys_p_lat_long'
    # Repository ID of the item, or its parent item, if a child within a
    # compound object.
    OBJECT_REPOSITORY_ID               = 'sys_k_object_repository_id'
    PAGE_NUMBER                        = 'sys_i_page_number'
    PARENT_ITEM                        = 'sys_k_parent_item'
    PRIMARY_MEDIA_CATEGORY             = 'sys_k_primary_media_category'
    # N.B.: An item might be published but its collection might not be, making
    # it still effectively unpublished. This will take that into account.
    PUBLICLY_ACCESSIBLE                = OpensearchIndex::StandardFields::PUBLICLY_ACCESSIBLE
    PUBLISHED                          = 'sys_b_published'
    PUBLISHED_AT                       = 'sys_d_published'
    REPOSITORY_ID                      = 'sys_k_repository_id'
    REPRESENTATIVE_FILENAME            = 'sys_k_representative_filename'
    REPRESENTATIVE_ITEM                = 'sys_k_representative_item_id'
    RESTRICTED                         = OpensearchIndex::StandardFields::RESTRICTED
    SEARCH_ALL                         = OpensearchIndex::StandardFields::SEARCH_ALL
    # Concatenation of various compound object page components or path
    # components (see as_indexed_json()) used for sorting items grouped
    # structurally.
    STRUCTURAL_SORT                    = 'sys_k_structural_sort'
    SUBPAGE_NUMBER                     = 'sys_i_subpage_number'
    TITLE                              = ItemElement.new(name: 'title').indexed_keyword_field
    TOTAL_BYTE_SIZE                    = 'sys_l_total_byte_size'
    VARIANT                            = 'sys_k_variant'
  end

  ##
  # N.B. When modifying these, modify {sort_key_for_variant} as well.
  #
  class Variants
    BACK_COVER         = 'BackCover'
    COMPOSITE          = 'Composite'
    DIRECTORY          = 'Directory'
    FILE               = 'File'
    FRONT_COVER        = 'FrontCover'
    FRONT_MATTER       = 'FrontMatter'
    INDEX              = 'Index'
    INSIDE_BACK_COVER  = 'InsideBackCover'
    INSIDE_FRONT_COVER = 'InsideFrontCover'
    KEY                = 'Key'
    PAGE               = 'Page'
    SUPPLEMENT         = 'Supplement'
    TABLE_OF_CONTENTS  = 'TableOfContents'
    THREE_D_MODEL      = '3DModel'
    TITLE              = 'Title'

    ##
    # @return [Enumerable<String>] String values of all variants.
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end

    ##
    # @return [Enumerable<String>] String values of all variants that are
    #                              not filesystem-related.
    #
    def self.non_filesystem_variants
      self.all.reject{ |v| [FILE, DIRECTORY].include?(v) }
    end
  end

  LOGGER = CustomLogger.new(Item)

  # In the order they should appear in the TSV, left-to-right.
  NON_DESCRIPTIVE_TSV_COLUMNS = %w(uuid parentId preservationMasterPathname
    preservationMasterFilename preservationMasterUUID accessMasterPathname
    accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
    published contentdmAlias contentdmPointer IGNORE)

  has_and_belongs_to_many :allowed_host_groups,
                          class_name: 'HostGroup',
                          association_foreign_key: :allowed_host_group_id
  has_and_belongs_to_many :effective_allowed_host_groups,
                          class_name: 'HostGroup',
                          association_foreign_key: :effective_allowed_host_group_id
  has_and_belongs_to_many :item_sets

  has_many :binaries, inverse_of: :item, dependent: :destroy
  has_many :elements, class_name: 'ItemElement', inverse_of: :item,
           dependent: :destroy

  serialize :allowed_netids, coder: JSON

  # VALIDATIONS

  # collection_repository_id
  validates_format_of :collection_repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid'
  # latitude
  validates :latitude, numericality: { greater_than: -90, less_than: 90 },
            allow_blank: true
  # longitude
  validates :longitude, numericality: { greater_than: -180, less_than: 180 },
            allow_blank: true
  # page_number
  validates :page_number, numericality: { only_integer: true,
                                          greater_than_or_equal_to: 1 },
            allow_blank: true
  # parent_repository_id
  validates_format_of :parent_repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  # repository_id
  validates_format_of :repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid'
  # representation_type
  validates :representation_type, inclusion: { in: Representation::Type.all.reject{ |t| t == Representation::Type::ITEM } },
            allow_blank: true
  # representative_item_id
  validates_format_of :representative_item_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  # subpage_number
  validates :subpage_number, numericality: { only_integer: true,
                                             greater_than_or_equal_to: 1 },
            allow_blank: true
  # variant
  validates :variant, inclusion: { in: Variants.all }, allow_blank: true

  validate :validate_representative_image_format
  validate :validate_title_exists

  # ACTIVERECORD CALLBACKS

  before_save :process_allowed_netids, :notify_netids,
              :prune_identical_elements, :set_effective_host_groups,
              :set_normalized_coords, :set_normalized_date, :set_published_at

  ##
  # @return [Boolean]
  # 
  def ocred?
    self.ocred 
  end

  ##
  # @return [Integer]
  #
  def self.num_free_form_files
    Item.search.
        include_variants(*Variants::FILE).
        aggregations(false).
        include_unpublished(true).
        include_publicly_inaccessible(true).
        include_restricted(true).
        search_children(true).
        limit(0).
        count
  end

  ##
  # @return [Integer]
  #
  def self.num_free_form_items
    Item.search.
        include_variants(Variants::FILE, Variants::DIRECTORY).
        aggregations(false).
        search_children(true).
        include_unpublished(true).
        include_publicly_inaccessible(true).
        include_restricted(true).
        limit(0).
        count
  end

  ##
  # @return [Integer] Number of objects in the application. This includes
  #                   {Variants::FILE files} and items with no parent.
  #
  def self.num_objects
    num_free_form_files + Item.search.
        aggregations(false).
        include_unpublished(true).
        include_publicly_inaccessible(true).
        include_restricted(true).
        search_children(false).
        exclude_variants(Variants::FILE, Variants::DIRECTORY).
        limit(0).
        count
  end

  ##
  # Returns an Enumerable of technical attributes, plus one element per
  # metadata profile element.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [Enumerable<String>] Enumerable of column names.
  #
  def self.tsv_columns(metadata_profile)
    columns = NON_DESCRIPTIVE_TSV_COLUMNS
    metadata_profile.elements.each do |ed|
      # There will be one column per MetadataProfileElement vocabulary. Column
      # headings are in the format "vocabKey:elementName", except the
      # uncontrolled vocabulary which will not have a vocabKey prefix.
      columns += ed.vocabularies.sort{ |v| v.key <=> v.key }.map do |vocab|
        vocab.key != Vocabulary::UNCONTROLLED_KEY ?
            "#{vocab.key}:#{ed.label}" : ed.label
      end
    end
    columns
  end

  ##
  # @param include_self [Boolean]
  # @return [ActiveRecord::Relation<Binary>] All binaries associated with every
  #                                          immediate child item.
  #
  def all_child_binaries(include_self: false)
    sql = 'SELECT binaries.id
        FROM binaries
        LEFT JOIN items AS binary_items ON binaries.item_id = binary_items.id
        LEFT JOIN items AS parent_items ON binary_items.parent_repository_id = parent_items.repository_id
        WHERE parent_items.id = $1'
    sql += ' OR binary_items.id = $2' if include_self

    values = [self.id]
    values << self.id if include_self

    results = ActiveRecord::Base.connection.exec_query(sql, 'SQL', values)
    binary_ids = results.map{ |row| row['id'] }
    Binary.where('id IN (?)', binary_ids)
  end

  ##
  # @return [ActiveRecord::Relation<Item>] All items that are children of the
  #                                        instance, at any level in the tree.
  # @see items
  # @see walk_tree
  #
  def all_children
    sql = 'WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[repository_id] AS breadcrumb
        FROM items h
        WHERE id = $1
        UNION ALL
        SELECT hi, q.level + 1 AS level, breadcrumb || repository_id
        FROM q
        JOIN items hi
          ON hi.parent_repository_id = (q.h).repository_id
      )
      SELECT (q.h).repository_id
      FROM q
      ORDER BY breadcrumb'
    values = [self.id]

    results = ActiveRecord::Base.connection.exec_query(sql, 'SQL', values)
    Item.where('repository_id IN (?)', results
                                           .select{ |row| row['repository_id'] != self.repository_id }
                                           .map{ |row| row['repository_id'] })
  end

  ##
  # @return [ActiveRecord::Relation<Item>] All items with a variant of
  #                                        {Variants::FILE} that are children
  #                                        of the instance, at any level in the
  #                                        tree.
  #
  def all_files(offset: nil, limit: nil)
    sql = 'WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[repository_id] AS breadcrumb
        FROM items h
        WHERE id = $1
        UNION ALL
        SELECT hi, q.level + 1 AS level, breadcrumb || repository_id
        FROM q
        JOIN items hi
          ON hi.parent_repository_id = (q.h).repository_id
      )
      SELECT (q.h).repository_id
      FROM q
      WHERE (q.h).variant = $2
      ORDER BY breadcrumb'
    sql += " OFFSET #{offset}" if offset
    sql += " LIMIT #{limit}" if limit

    values = [self.id, Variants::FILE]

    results = ActiveRecord::Base.connection.exec_query(sql, 'SQL', values)
    Item.where('repository_id IN (?)', results.map{ |row| row['repository_id'] })
  end

  ##
  # @return [Enumerable<Item>] All parents in order from closest to farthest.
  #
  def all_parents
    parents = []
    p = self.parent
    while p
      parents << p
      p = p.parent
    end
    parents
  end

  ##
  # @return [Hash] Harvestable representation. This does not include any links
  #                (URLs).
  #
  def as_harvestable_json
    access_master_struct = nil
    bin = self.effective_image_binary
    if bin&.image_server_safe?
      access_master_struct = {
          id:         bin.medusa_uuid,
          object_uri: bin.uri,
          media_type: bin.media_type
      }
    end
    {
        class:                   self.class.to_s,
        id:                      self.repository_id,
        normalized_start_date:   self.start_date,
        normalized_end_date:     self.end_date,
        normalized_latitude:     self.latitude&.to_f,
        normalized_longitude:    self.longitude&.to_f,
        variant:                 self.variant,
        preservation_media_type: self.binaries
                                     .where(master_type: Binary::MasterType::PRESERVATION)
                                     .limit(1)
                                     .first&.media_type,
        access_master_image:     access_master_struct,
        elements:                self.elements_in_profile_order(only_visible: true)
                                     .map{ |e| { name: e.name, value: e.value } },
        full_text:               self.full_text,
        created_at:              self.created_at,
        published_at:            self.published_at,
        updated_at:              self.updated_at
    }
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]                   = self.class.to_s
    doc[IndexFields::COLLECTION]              = self.collection_repository_id
    # OpenSearch date fields don't support >4-digit years.
    if self.date && self.date.year < 10000
      doc[IndexFields::DATE]                  = self.date.utc.iso8601
    end
    doc[IndexFields::DESCRIBED]               = self.described?
    doc[IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS] =
        self.effective_allowed_host_groups.pluck(:key)
    doc[IndexFields::EFFECTIVE_ALLOWED_HOST_GROUP_COUNT] =
        doc[IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS].length
    doc[IndexFields::FULL_TEXT]               = self.full_text
    doc[IndexFields::ITEM_SETS]               = self.item_sets.pluck(:id)
    doc[IndexFields::LAST_INDEXED]            = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]           = self.updated_at.utc.iso8601
    if self.latitude && self.longitude
      doc[IndexFields::LAT_LONG]              = { lon: self.longitude, lat: self.latitude }
    end
    doc[IndexFields::OBJECT_REPOSITORY_ID]    = self.collection&.free_form? ?
                                                    self.repository_id :
                                                    (self.parent_repository_id || self.repository_id)
    doc[IndexFields::PAGE_NUMBER]             = self.page_number
    doc[IndexFields::PARENT_ITEM]             = self.parent_repository_id
    doc[IndexFields::PRIMARY_MEDIA_CATEGORY]  = self.primary_media_category
    doc[IndexFields::PUBLICLY_ACCESSIBLE]     = self.publicly_accessible?
    doc[IndexFields::PUBLISHED]               = self.published
    doc[IndexFields::PUBLISHED_AT]            = self.published_at&.utc&.iso8601
    doc[IndexFields::REPOSITORY_ID]           = self.repository_id
    doc[IndexFields::REPRESENTATIVE_FILENAME] = self.representative_filename
    doc[IndexFields::REPRESENTATIVE_ITEM]     = self.representative_item_id
    doc[IndexFields::RESTRICTED]              = self.restricted
    doc[IndexFields::STRUCTURAL_SORT]         = structural_sort_key
    doc[IndexFields::SUBPAGE_NUMBER]          = self.subpage_number
    doc[IndexFields::TOTAL_BYTE_SIZE]         = self.binaries.pluck(:byte_size).sum
    doc[IndexFields::VARIANT]                 = self.variant

    # Index metadata elements into dynamic fields.
    self.elements.select{ |e| e.value.present? }.each do |element|
      # Skip non-indexable elements. Elements are considered indexable if they
      # are marked as indexed in the collection's metadata profile, or if the
      # collection doesn't have a metadata profile.
      next unless (!self.collection&.metadata_profile ||
          self.collection&.metadata_profile.elements.
              find{ |mpe| mpe.name == element.name }&.indexed)

      # ES will automatically create a one or more multi fields for this.
      if element.value.present?
        unless doc[element.indexed_field]&.respond_to?(:each)
          doc[element.indexed_field] = []
        end
        doc[element.indexed_field] <<
            StringUtils.strip_leading_articles(element.value)[0..OpensearchClient::MAX_KEYWORD_FIELD_LENGTH]
      end
    end

    # We also need to index parent metadata fields. These are needed when we
    # want to find parents matching a query, and include them and all of their
    # children in results.
    if self.parent
      self.parent.elements.each do |element|
        if element.value.present?
          unless doc[element.parent_indexed_field]&.respond_to?(:each)
            doc[element.parent_indexed_field] = []
          end
          doc[element.parent_indexed_field] <<
              StringUtils.strip_leading_articles(element.value)[0..OpensearchClient::MAX_KEYWORD_FIELD_LENGTH]
        end
      end
    end

    doc
  end

  ##
  # N.B.: This method must be kept in sync with {update_from_json}.
  #
  # @return [Hash] Complete JSON representation of the instance. This may
  #                include private information that is not appropriate for
  #                public consumption.
  #
  def as_json(options = {})
    struct = super(options)
    struct['start_date'] = self.start_date&.utc&.iso8601
    struct['end_date']   = self.end_date&.utc&.iso8601
    # Add children
    struct['children'] = []
    self.items.each { |it| struct['children'] << it.as_json.select{ |k, v| k == 'repository_id' } }
    # Add binaries
    struct['binaries'] = []
    self.binaries.each { |b| struct['binaries'] << b.as_json.except(:item_id) }
    # Add ItemElements
    struct['elements'] = self.elements.map(&:as_json)
    struct
  end

  ##
  # @return [String, nil] Value of the `bibId` element.
  #
  def bib_id
    self.element(:bibId)&.value
  end

  ##
  # @return [String, nil] URL of the instance in the library's OPAC. Will be
  #                       nil if the instance's bib ID is nil.
  #
  def catalog_record_url
    # See https://bugs.library.illinois.edu/browse/DLD-342
    #
    # N.B.: "The bib IDs currently in the digital library will have to have 99
    # added to the beginning and 12205899 added to the end to create the mms
    # id, however it's likely that eventually new items will have the mms id
    # instead of a bib id from voyager, so to get around that you could first
    # check to see if the bib ID has 99 at the beginning and 5899 at the end of
    # the id."
    #
    # N.B. 2: this method is also used by Book Tracker in
    # Book.uiuc_catalog_url(). These methods should be kept in sync.
    bibid = self.bib_id
    if bibid.present?
      base_url = 'https://i-share-uiu.primo.exlibrisgroup.com/permalink/01CARLI_UIU/gpjosq/alma'
      prefix   = '99'
      suffix   = '12205899'
      return [base_url,
              bibid.start_with?(prefix) ? '' : prefix,
              bibid,
              bibid.end_with?(suffix) ? '' : suffix].join
    end
    nil
  end

  ##
  # @return [Collection]
  #
  def collection
    unless @collection
      @collection = Collection.find_by_repository_id(self.collection_repository_id)
    end
    @collection
  end

  ##
  # This is dangerous and should only be used in testing. The DLS/Medusa
  # architecture does not allow items to be moved between collections.
  #
  # @param collection [Collection]
  #
  def collection=(collection)
    self.collection_repository_id = collection.repository_id
    @collection = collection
  end

  ##
  # @return [Boolean] Whether the instance has any children with a
  #                   {Variants::PAGE page variant}.
  #
  def compound?
    self.variant.blank? && self.pages.count > 0
  end

  ##
  # Alias of {start_date}.
  #
  def date
    start_date
  end

  ##
  # @return [String,nil]
  # @see http://dublincore.org/documents/dcmi-type-vocabulary/#H7
  #
  def dc_type
    self.compound? ? 'Collection' : self.effective_viewer_binary&.dc_type
  end

  ##
  # An item is considered described if it has any elements other than `title`,
  # or is in a collection using the {PackageProfile::FREE_FORM_PROFILE
  # free-form package profile}.
  #
  # @return [Boolean]
  #
  def described?
    if self.collection&.free_form?
      (self.directory? || self.elements.select{ |e| e.name == 'title' }.any?)
    else
      self.elements.reject{ |e| e.name == 'title' }.any?
    end
  end

  ##
  # @return [Boolean] Whether the variant is {Variants::DIRECTORY}.
  #
  def directory?
    self.variant == Variants::DIRECTORY
  end

  ##
  # Overrides the same method in [Representable].
  #
  def effective_file_representation
    rep      = Representation.new
    rep.type = self.representation_type
    case rep.type
    when Representation::Type::MEDUSA_FILE, Representation::Type::SELF
      rep.type = Representation::Type::MEDUSA_FILE
      rep.file = self.effective_image_binary&.medusa_file
    when Representation::Type::LOCAL_FILE
      rep.key = self.representative_image_key_prefix + self.representative_image
    end
    rep
  end

  ##
  # Returns the best binary to use with an image server, guaranteed to be
  # compatible with it, in the following order of preference:
  #
  # 1. The representative binary
  # 2. If the instance's variant is {Variants::SUPPLEMENT}, any binary
  # 3. If the instance is compound, the {effective_image_binary} of the first
  #    child, sorted structurally
  # 4. Any access master of {Binary::MediaCategory::IMAGE}
  # 5. Any access master of {Binary::MediaCategory::VIDEO}
  # 6. Any access master with media type `application/pdf`
  # 7. Any preservation master of {Binary::MediaCategory::IMAGE}
  # 8. Any preservation master of {Binary::MediaCategory::VIDEO}
  # 9. Any preservation master with media type `application/pdf`
  #
  # @return [Binary, nil]
  # @see effective_viewer_binary
  #
  def effective_image_binary # TODO: this is very similar to effective_viewer_binary()
    unless @effective_image_binary
      bin = nil
      begin
        bin = self.representative_medusa_file_id.present? ?
                Binary.from_medusa_file(file: self.representative_medusa_file) : nil
      rescue => e
        LOGGER.warn("effective_image_binary(): #{e} [item: %s]", self.repository_id)
      end
      if !bin || !bin.image_server_safe?
        if self.variant == Variants::SUPPLEMENT
          bin = self.binaries.first
        elsif self.compound?
          first_child = self.search_children.
              include_restricted(true).
              include_unpublished(true).
              include_publicly_inaccessible(true).
              limit(1).
              to_a.first
          # This should always be true, but just to make sure we prevent a
          # circular reference...
          if first_child && first_child.repository_id != self.repository_id
            bin = first_child.effective_image_binary
          end
        end
        if !bin || !bin.image_server_safe?
          [
              {
                  master_type: Binary::MasterType::ACCESS,
                  media_category: Binary::MediaCategory::IMAGE
              },
              {
                  master_type: Binary::MasterType::ACCESS,
                  media_category: Binary::MediaCategory::VIDEO
              },
              {
                  master_type: Binary::MasterType::ACCESS,
                  media_type: 'application/pdf'
              },
              {
                  master_type: Binary::MasterType::PRESERVATION,
                  media_category: Binary::MediaCategory::IMAGE
              },
              {
                  master_type: Binary::MasterType::PRESERVATION,
                  media_category: Binary::MediaCategory::VIDEO
              },
              {
                  master_type: Binary::MasterType::PRESERVATION,
                  media_type: 'application/pdf'
              }
          ].each do |pref|
            bin = self.binaries.select do |b|
              b.master_type == pref[:master_type] &&
                  (pref[:media_category] ?
                       (b.media_category == pref[:media_category]) :
                       (b.media_type == pref[:media_type]))
            end
            bin = bin.first
            break if bin
          end
        end
      end
      @effective_image_binary = bin
    end
    @effective_image_binary
  end

  ##
  # Overrides the same method in [Representable]. The effective representative
  # item associated with the returned instance is based on the following order
  # of preference:
  #
  # 1. The instance's {representative_item}
  # 2. The instance's front cover page
  # 3. The instance's title page
  # 4. The instance's first page
  # 5. The instance itself
  #
  # @return [Representation]
  # @see representative_item
  #
  def effective_representation
    rep = Representation.new
    rep.type = Representation::Type::ITEM
    rep.item = self.representative_item ||
      self.items.
        where(variant: [Variants::FRONT_COVER, Variants::TITLE, Variants::PAGE]).
        order(:variant, :page_number).
        limit(1).first ||
      self
    rep
  end

  ##
  # N.B.: a rights statement differs from a rights term (e.g.
  # {effective_rights_term}) in that the statement is free-form and the term is
  # drawn from some controlled vocabulary.
  #
  # @return [String, nil] Rights description assigned to the instance, if
  #                       present; otherwise, rights statement,
  #                       if present; otherwise nil.
  # @see effective_rights_term
  #
  def effective_rights_statement
    # iterate through elments to retrieve rights description value
    rs = self.elements.find{ |e| e.name == 'accessRights' && e.value.present? }&.value 
    # if blank, iterate through elements to retrieve the statement assigned to the instance.
    if rs.blank?
      rs = self.elements.find{ |e| e.name == 'rights' && e.value.present? }&.value
    end
    rs
  end

  ##
  # @return [VocabularyTerm, nil] Term assigned to the instance, if present;
  #                               otherwise, the closest ancestor rights term,
  #                               if present; otherwise, the statement assigned
  #                               to its owning [Collection], if present;
  #                               otherwise nil.
  # @see rights_term
  #
  def effective_rights_term
    # Use the statement assigned to the instance.
    uri = self.elements.find{ |e| e.uri&.include?('://rightsstatements.org') ||
      e.uri&.include?('://creativecommons.org') }&.uri
    term = VocabularyTerm.find_by_uri(uri)
    # If not assigned, walk up the item tree to find a parent statement.
    unless term
      p = self.parent
      while p
        uri = p.elements.find{ |e| e.uri&.include?('://rightsstatements.org') ||
          e.uri&.include?('://creativecommons.org') }&.uri
        term = VocabularyTerm.find_by_uri(uri)
        break if term
        p = p.parent
      end
    end
    # If still no statement available, use the collection's statement.
    term = VocabularyTerm.find_by_uri(self.collection.rights_term_uri) unless term
    term
  end

  ##
  # Returns the best binary to use for a main viewer. It may or may not be an
  # image.
  #
  # 1. The representative binary
  # 2. If the instance's variant is {Variants::SUPPLEMENT}, any binary
  # 3. If the instance is compound, the {effective_image_binary} of the first
  #    child, sorted structurally
  # 4. Any access master of {Binary::MediaCategory::IMAGE}
  # 5. Any other access master
  # 6. Any preservation master of {Binary::MediaCategory::IMAGE}
  # 7. Any other preservation master
  #
  # @return [Binary, nil]
  # @see effective_image_binary
  #
  def effective_viewer_binary # TODO: this is very similar to effective_image_binary()
    unless @effective_viewer_binary
      bin = nil
      begin
        bin = self.representative_medusa_file_id.present? ?
                Binary.from_medusa_file(file: self.representative_medusa_file) : nil
      rescue => e
        LOGGER.warn("effective_viewer_binary(): #{e} [item: %s]", self.repository_id)
      end
      if !bin or !bin.image_server_safe?
        if self.variant == Variants::SUPPLEMENT
          bin = self.binaries.first
        elsif self.compound?
          bin = self.search_children.limit(1).to_a.first&.effective_image_binary
        end
        if !bin || !bin.image_server_safe?
          [
              {
                  master_type: Binary::MasterType::ACCESS,
                  media_category: Binary::MediaCategory::IMAGE
              },
              {
                  master_type: Binary::MasterType::ACCESS,
                  media_category: nil
              },
              {
                  master_type: Binary::MasterType::PRESERVATION,
                  media_category: Binary::MediaCategory::IMAGE
              },
              {
                  master_type: Binary::MasterType::PRESERVATION,
                  media_category: nil
              }
          ].each do |pref|
            result = self.binaries.find do |b|
              b.master_type == pref[:master_type] &&
                  (pref[:media_category] ?
                       (b.media_category == pref[:media_category]) : true)
            end
            if result
              bin = result
              break
            end
          end
        end
      end
      @effective_viewer_binary = bin
    end
    @effective_viewer_binary
  end

  ##
  # @param only_visible [Boolean]
  # @return [Enumerable<ItemElement>] The instance's [ItemElement]s in the
  #                                   order of the elements in the collection's
  #                                   metadata profile.
  #
  def elements_in_profile_order(only_visible: false)
    mp_elements  = self.collection.metadata_profile.elements
    mp_elements  = mp_elements.where(visible: true) if only_visible
    all_elements = []
    mp_elements.each do |mpe|
      all_elements += self.elements.select{ |e| e.name == mpe.name }
    end
    all_elements
  end

  ##
  # @return [Boolean] Whether the variant is {Variants::FILE}.
  #
  def file?
    self.variant == Variants::FILE
  end

  ##
  # @return [String,nil] Full text of an attached binary that has it (if any).
  #
  def full_text
    self.full_text_binary&.full_text
  end

  ##
  # @return [Binary,nil] An attached binary that has full text (if any).
  #
  def full_text_binary
    self.binaries.find{ |b| b.full_text.present? }
  end

  ##
  # @return [Boolean]
  #
  def has_iiif_manifest?
    self.compound? ||
        [Variants::DIRECTORY, Variants::FILE].include?(self.variant) ||
        !self.variant
  end

  ##
  # @param include_children [Boolean] Whether to include immediate children in
  #                                   the search.
  # @return [Boolean] Whether the instance (or any of its immediate children,
  #                   if specified) has an attached binary with full text.
  #
  def has_full_text?(include_children: false)
    return true if self.full_text.present?
    if include_children
      return Binary.joins(:item).
        where('items.parent_repository_id = ?', self.repository_id).
        where('binaries.full_text IS NOT NULL').
        count > 0
    end
    false
  end

  ##
  # @return [ActiveRecord::Relation<Item>] Immediate child items.
  # @see all_children
  #
  def items
    Item.where(parent_repository_id: self.repository_id)
  end

  ##
  # Transactionally migrates elements with the given source name to new
  # elements with the given destination name, and then deletes the source
  # elements.
  #
  # Call {reload} afterwards to refresh the `elements` relationship.
  #
  # @param source_name [String] Source element name
  # @param dest_name [String] Destination element name
  # @return [void]
  #
  def migrate_elements(source_name, dest_name)
    transaction do
      # Get all of the elements with the same name as the source element
      self.elements.select{ |e| e.name == source_name }.each do |src_e|
        # Clone them into elements with the destination name.
        new_e = src_e.dup
        new_e.name = dest_name
        self.elements << new_e
        src_e.destroy!
      end
      self.save!
    end
  end

=begin
  ##
  # @return [ItemRelation] New instance initialized to return all children with
  #                        a {Variants::PAGE page variant}.
  #
  def pages TODO: why is this so slow?
    self.search_children.include_variants(Variants::PAGE).
        order(IndexFields::PAGE_NUMBER).
        order(IndexFields::SUBPAGE_NUMBER)
  end
=end

  ##
  # @param recursive [Boolean] If `true`, binaries of all child items are
  #                            included, including children of children.
  # @return [Enumerable<Binary>]
  #
  def ocrable_binaries(recursive: false)
    binaries = recursive ? all_child_binaries(include_self: true) : self.binaries
    binaries.
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
  end

  ##
  # @param recursive [Boolean] If `true`, binaries of all child items are
  #                            included, including children of children.
  # @return [Enumerable<Binary>]
  #
  def ocred_binaries(recursive: false)
    self.ocrable_binaries(recursive: recursive).where('ocred_at IS NOT NULL')
  end

  ##
  # @return [ActiveRecord::Relation<Item>] All children with a
  #                                        {Variants::PAGE page variant}.
  #
  def pages
    self.items.where(variant: Variants::PAGE)
        .order(:page_number, :subpage_number)
  end

  ##
  # @return [Item, nil]
  # @see all_parents
  #
  def parent
    @parent = Item.find_by_repository_id(self.parent_repository_id) unless @parent
    @parent
  end

  ##
  # Infers the primary media category of the instance by analyzing its
  # binaries' media categories.
  #
  # @return [Integer, nil] One of the {Binary::MediaCategory} constant values.
  #
  def primary_media_category
    counts = {}
    self.binaries.each do |bin|
      mc = bin.media_category
      if mc.present?
        if counts.key?(mc)
          counts[mc] += 1
        else
          counts[mc] = 1
        end
      end
    end
    counts.max_by{ |k,v| v }&.first
  end

  ##
  # Transactionally propagates [HostGroup]s from the instance to all of its
  # children.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_heritable_properties(task = nil)
    num_items = self.items.count
    self.walk_tree do |item, index|
      transaction do
        item.save!
        if task && index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Boolean] Whether the instance its collection, and its parent(s)
  #                   (if any) are all publicly accessible.
  #
  def publicly_accessible?
    value = self.published && self.collection&.publicly_accessible?
    if value && self.parent
      value = self.parent.publicly_accessible?
    end
    value
  end

  ##
  # @return [String] Filename of the representative binary.
  #
  def representative_filename
    bin = self.binaries.
        where('object_key IS NOT NULL').
        where('media_category != ?', Binary::MediaCategory::THREE_D).
        order(:master_type).
        limit(1).
        first
    bin&.filename&.split('.')&.first
  end

  ##
  # @return [Boolean]
  #
  def restricted
    (self.collection&.restricted || self.allowed_netids&.any?) ? true : false
  end

  ##
  # @return [VocabularyTerm, nil]
  # @see effective_rights_term
  #
  def rights_term
    uri = self.elements.find{ |e| e.uri&.include?('://rightsstatements.org') ||
      e.uri&.include?('://creativecommons.org') }&.uri
    VocabularyTerm.find_by_uri(uri)
  end

  ##
  # @return [Item] The root parent, or the instance itself if it has no parent.
  #
  def root_parent
    if self.parent
      return all_parents.last
    end
    self
  end

  ##
  # @return [ItemRelation] New instance initialized to search for child items.
  #
  def search_children
    Item.search.
      parent_item(self).
      aggregations(false).
      include_children_in_results(true).
      search_children(true).
      include_restricted(true).
      order("#{Item::IndexFields::STRUCTURAL_SORT}#{ItemElement::SORT_FIELD_SUFFIX}")
  end

  ##
  # @return [ItemRelation] New instance initialized to search within the
  #         instance's own document.
  #
  def search_self
    Item.search.
      aggregations(false).
      include_restricted(true).
      query(Item::IndexFields::REPOSITORY_ID, self.repository_id)
  end

  ##
  # @return [Item]
  #
  def supplementary_item
    self.items.where(variant: Variants::SUPPLEMENT).limit(1).first
  end

  ##
  # @return [Item] The item's 3D model item, if available.
  #
  def three_d_item
    self.items.where(variant: Variants::THREE_D_MODEL).limit(1).first
  end

  def to_param
    self.repository_id
  end

  def to_s
    self.title
  end

  ##
  # Transactionally updates an instance's metadata elements from the metadata
  # embedded within its preservation or access master binary.
  #
  # @param include_date_created [Boolean]
  # @raises [IOError]
  #
  def update_from_embedded_metadata(include_date_created: false)
    return unless self.binaries.any?
    transaction do
      self.elements.destroy_all
      self.elements += elements_from_embedded_metadata(include_date_created: include_date_created)
      # Add a title (because it's required) in case the embedded metadata
      # didn't contain one.
      unless self.element(:title)
        pres_master = self.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION }
        if pres_master
          filename = pres_master.object_key.split("/").last
          title    = File.basename(filename, File.extname(filename))
        else
          title = self.repository_id
        end
        self.elements.build(name:       "title",
                            value:      title,
                            vocabulary: Vocabulary.uncontrolled)
      end
      self.save!
    end
  end

  ##
  # Updates an instance from a JSON representation compatible with the structure
  # returned by `as_json`.
  #
  # N.B.: This method must be kept in sync with {as_json}.
  #
  # @param json [String]
  # @return [void]
  # @raises [ArgumentError]
  #
  def update_from_json(json)
    struct = JSON.parse(json)
    transaction do
      # INSTANCE PROPERTIES
      # collection_repository_id is not modifiable
      self.contentdm_alias = struct['contentdm_alias']
      self.contentdm_pointer = struct['contentdm_pointer']
      # created_at is not modifiable
      # date is not modifiable
      self.embed_tag = struct['embed_tag']
      # id is not modifiable
      # latitude is not modifiable
      # longitude is not modifiable
      self.page_number = struct['page_number']
      # parent_repository_id is not modifiable
      self.published = struct['published']
      self.published_at = Time.parse(struct['published_at']) if struct['published_at']
      # repository_id is not modifiable
      self.representative_item_id = struct['representative_item_id']
      self.subpage_number = struct['subpage_number']
      # updated_at is not modifiable
      self.variant = struct['variant']

      # ELEMENTS
      # Current elements need to be deleted first, otherwise an update would
      # not be able to remove them.
      self.elements.destroy_all

      if struct['elements'].respond_to?(:each)
        struct['elements'].each do |se|
          # Add a new element
          ie = ItemElement.named(se['name'])
          if ie # TODO: raise an error if this is nil
            ie.uri         = se['uri']&.strip
            ie.value       = se['string']&.strip
            ie.vocabulary  = Vocabulary.find_by_key(se['vocabulary'])
            self.elements << ie
          end
        end
      end

      self.save!
    end
  end

  ##
  # Updates an instance from a hash representing a TSV row.
  #
  # @param row [Hash<String,String>] Item serialized as a TSV row
  # @return [Item]
  # @raises [ArgumentError] If a column heading contains an unrecognized
  #                         element name or vocabulary prefix
  #
  def update_from_tsv(row)
    transaction do
      # Metadata elements need to be deleted first, otherwise an update
      # wouldn't be able to remove them.
      self.elements.destroy_all

      # repository ID
      self.repository_id = row['uuid'].strip if row['uuid']

      # Parent item ID. If the TSV is coming from a DLS export, it will have a
      # parentId column. Otherwise, if it's coming from a Medusa export, we
      # will have to search for it based on the collection's package profile.
      if row.keys.include?('parentId')
        self.parent_repository_id = row['parentId']
      else
        self.parent_repository_id = self.collection.package_profile.
            parent_id_from_medusa(self.repository_id)
      end

      # CONTENTdm alias ("CISOROOT")
      self.contentdm_alias = row['contentdmAlias'].strip if row['contentdmAlias']

      # CONTENTdm pointer ("CISOPTR")
      self.contentdm_pointer = row['contentdmPointer'].strip if row['contentdmPointer']

      # page number
      self.page_number = row['pageNumber'].strip.to_i if row['pageNumber']

      # subpage number
      self.subpage_number = row['subpageNumber'].strip.to_i if
          row['subpageNumber']

      # published
      self.published = StringUtils.to_b(row['published']) if row['published']

      # variant
      self.variant = row['variant'].strip if row['variant']

      # Descriptive metadata elements.
      row.each do |heading, raw_value|
        # Vocabulary columns will have a heading of "vocabKey:elementLabel",
        # except uncontrolled columns which will have a heading of just
        # "elementLabel".
        heading_parts = heading.to_s.split(':')
        element_label = heading_parts.last
        element_name  = self.collection.metadata_profile.elements.
            find{ |e| e.label == element_label }&.name

        # Skip non-descriptive columns.
        next if NON_DESCRIPTIVE_TSV_COLUMNS.include?(element_label)

        if element_name
          # Get the vocabulary based on the prefix in the column heading.
          vocabulary = nil
          if heading_parts.length > 1
            vocabulary = Vocabulary.find_by_key(heading_parts.first)
            unless vocabulary
              raise ArgumentError, "Column contains an unrecognized vocabulary "\
                  "key: #{heading_parts.first}"
            end
          end
          self.elements += ItemElement::elements_from_tsv_string(
              element_name, raw_value, vocabulary)
        else
          raise ArgumentError, "Column contains an element not present in the "\
              "metadata profile: #{element_label}"
        end
      end
      self.save!
    end
  end

  ##
  # Items don't have filenames because they aren't files, but sometimes it's
  # necessary to present them as if they were. This makes more sense for items
  # that have only one attached binary, like free-form items.
  #
  # @return [String] Filename of a preservation master, if available; or an
  #                  access master, if available; or nil.
  #
  def virtual_filename
    bin = nil
    if self.binaries.any?
      bin = self.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION } ||
          self.binaries.find{ |b| b.master_type == Binary::MasterType::ACCESS }
    end
    bin&.filename
  end

  ##
  # Accepts a block to perform on the instance and all subitems in the tree.
  #
  def walk_tree(&block)
    index = 0
    yield(self, index)
    walk(self, index, &block)
  end


  private

  def elements_for_iim_value(iim_elem_label, dest_elem, iim_metadata)
    src_elem = iim_metadata.find{ |e| e[:label] == iim_elem_label }
    src_elem ? elements_for_value(src_elem[:value], dest_elem) : []
  end

  ##
  # @param value [String,Enumerable]
  # @param dest_elem [String]
  # @return [Enumerable<ItemElement>]
  #
  def elements_for_value(value, dest_elem)
    value = [value] unless value.respond_to?(:each)
    # "-" is a junk value that has been known to exist in our IPTC metadata.
    value.select{ |v| v.present? && v != '-' }.map do |val|
      ItemElement.new(name: dest_elem, value: val,
                      vocabulary: Vocabulary.uncontrolled)
    end
  end

  ##
  # @param include_date_created [Boolean]
  # @return [Enumerable<ItemElement>]
  #
  def elements_from_embedded_metadata(include_date_created: false)
    elements = []

    # Get the binary from which the metadata will be extracted.
    # First, try to get the preservation master image.
    bin = self.binaries.find{ |b| b.master_type == Binary::MasterType::PRESERVATION &&
        b.media_category == Binary::MediaCategory::IMAGE }
    # If that wasn't available, try to get any image.
    unless bin
      bin = self.binaries.find{ |b| b.media_category == Binary::MediaCategory::IMAGE }
      unless bin
        LOGGER.info('elements_from_embedded_metadata(): no binaries')
        return elements
      end
    end

    LOGGER.debug('elements_from_embedded_metadata(): using %s (%s)',
                 bin.human_readable_master_type, bin.object_key)

    # Get its embedded XMP metadata, falling back to IIM
    metadata = bin.metadata.select{ |m| m[:category] == 'XMP' }
    if metadata.empty?
      metadata = bin.metadata.select{ |m| m[:category] == 'IPTC' }
    end

    # See discussion in IMET-246
    # See: https://docs.google.com/spreadsheets/d/15Wf75vzP-rW-lrYzLHATjv1bI3xcMMSVbdBShy4t55A/edit
    # See: http://www.iptc.org/std/photometadata/specification/IPTC-PhotoMetadata

    # Title
    # Hack to treat items in a particular collection differently (IMET-397) TODO: revisit this
    if self.collection_repository_id == '8838a520-2b19-0132-3314-0050569601ca-7'
      title = { value: File.basename(bin.object_key) }
    else
      title = metadata.find{ |e| e[:label] == 'Headline' }
      unless title
        title = metadata.find{ |e| e[:label] == 'Title' }
        unless title
          title = metadata.find{ |e| e[:label] == 'Object Name' }
        end
      end
    end
    elements += elements_for_value(title[:value], 'title') if title

    # Date Created
    if include_date_created
      elements += elements_for_iim_value('Date', 'dateCreated', metadata)
    end

    # Creator
    creator = metadata.find{ |e| e[:label] == 'Creator' }
    unless creator
      creator = metadata.find{ |e| e[:label] == 'By-line' }
      unless creator
        creator = metadata.find{ |e| e[:label] == 'Credit Line' }
      end
    end
    elements += elements_for_value(creator[:value], 'creator') if creator

    # Description
    desc = metadata.find{ |e| e[:label] == 'Description' }
    unless desc
      desc = metadata.find{ |e| e[:label] == 'Caption' }
      unless desc
        desc = metadata.find{ |e| e[:label] == 'Abstract' }
      end
    end
    elements += elements_for_value(desc[:value], 'description') if desc

    # Copyright Notice
    elements += elements_for_iim_value('Copyright Notice', 'rights', metadata)

    # Rights Usage Terms
    elements += elements_for_iim_value('Rights Usage Terms', 'license', metadata)

    # Keywords
    elements += elements_for_iim_value('Keywords', 'keyword', metadata)

    # Sublocation
    elements += elements_for_iim_value('Sublocation', 'streetAddress', metadata)

    # City
    elements += elements_for_iim_value('City', 'addressLocality', metadata)

    # Province or State
    elements += elements_for_iim_value('Province or State', 'addressRegion', metadata)

    # Country Name
    elements += elements_for_iim_value('Country Name', 'addressCountry', metadata)

    # Copy sublocation, city, province or state, and country name into keyword
    # elements.
    elements += elements_for_iim_value('Sublocation', 'keyword', metadata)
    elements += elements_for_iim_value('City', 'keyword', metadata)
    elements += elements_for_iim_value('Province or State', 'keyword', metadata)
    elements += elements_for_iim_value('Country Name', 'keyword', metadata)

    elements
  end

  ##
  # @return [void]
  #
  def inherit_host_groups
    allowed_hgs = []
    # Try to inherit from an ancestor.
    p = self.parent
    while p && allowed_hgs.empty?
      allowed_hgs = p.allowed_host_groups
      p = p.parent
    end
    # If no ancestor has any host groups, inherit from the collection.
    if allowed_hgs.empty? && self.collection
      allowed_hgs = self.collection.allowed_host_groups
    end

    transaction do
      self.effective_allowed_host_groups.destroy_all
      allowed_hgs.each do |group|
        self.effective_allowed_host_groups << group
      end
    end
  end

  def notify_netids
    if self.allowed_netids&.any? && !Rails.env.development?
      prev_netids = self.allowed_netids_was&.map{ |h| h['netid'] } || []
      new_netids  = self.allowed_netids.map{ |h| h['netid'] } - prev_netids
      new_netids.each do |netid|
        KumquatMailer.restricted_item_available(self, netid).deliver_now
      end
    end
  end

  def process_allowed_netids
    if allowed_netids&.any?
      allowed_netids.each_with_index do |h, i|
        allowed_netids[i]['netid']   = h['netid'].strip
        allowed_netids[i]['expires'] = Time.now.to_i + 21.days.to_i if h['expires'].blank?
      end
      allowed_netids.select!{ |h| h['netid'].present? }
    end
  end

  ##
  # Removes duplicate elements, ensuring that all are unique.
  #
  def prune_identical_elements
    transaction do
      all_elements = self.elements.to_a
      unique_elements = []
      all_elements.each do |e|
        if unique_elements.select{ |ue| e == ue }.empty?
          unique_elements << e
        end
      end
      (all_elements - unique_elements).each(&:destroy!)
    end
  end

  ##
  # Overrides the same method in [Representable].
  #
  def representative_image_key_prefix
    "representative_images/item/#{repository_id}/"
  end

  ##
  # Populates {effective_allowed_host_groups}.
  #
  # @return [void]
  #
  def set_effective_host_groups
    allowed_hgs = self.allowed_host_groups
    if allowed_hgs.any?
      transaction do
        self.effective_allowed_host_groups.destroy_all
        allowed_hgs.each do |group|
          self.effective_allowed_host_groups << group
        end
      end
    else
      inherit_host_groups
    end
  end

  ##
  # Tries to set the normalized latitude & longitude from a `coordinates`
  # element.
  #
  def set_normalized_coords
    coords_elem = self.element(:coordinates)
    if coords_elem
      coords = SpaceUtils.string_coordinates_to_coordinates(coords_elem.value)
      if coords
        self.latitude  = coords[:latitude]
        self.longitude = coords[:longitude]
      end
    end
  end

  ##
  # Tries to set the normalized date from a `date` element.
  #
  def set_normalized_date
    updated = false
    date_elem = self.element(:date)
    if date_elem
      range = TimeUtils.parse_date(date_elem.value)
      if range
        self.start_date = range[0]
        self.end_date   = range[1]
        updated = true
      end
    end
    unless updated
      self.start_date = nil
      self.end_date   = nil
    end
  end

  ##
  # Sets the `published_at` attribute.
  #
  def set_published_at
    if self.published_at.nil? && self.published
      if [Variants::FILE, Variants::DIRECTORY].include?(self.variant) ||
          self.elements.reject{ |e| e.name == 'title' }.any?
        self.published_at = Time.now
      end
    end
  end

  def sort_key_for_variant
    case self.variant
      when Variants::FRONT_COVER
        return 'caa'
      when Variants::INSIDE_FRONT_COVER
        return 'daa'
      when Variants::TITLE
        return 'eaa'
      when Variants::FRONT_MATTER
        return 'faa'
      when Variants::TABLE_OF_CONTENTS
        return 'gaa'
      when Variants::KEY
        return 'haa'
      when Variants::PAGE
        return 'iaa'
      when Variants::INDEX
        return 'jaa'
      when Variants::INSIDE_BACK_COVER
        return 'kaa'
      when Variants::BACK_COVER
        return 'laa'
      when Variants::SUPPLEMENT
        return 'maa'
      when Variants::COMPOSITE
        return 'naa'
      when Variants::THREE_D_MODEL
        return 'oaa'
      else
        return 'baa' # N.B.: "aaa" is the absolute first-sort token.
    end
  end

  ##
  # @return [String]
  #
  def structural_sort_key
    # N.B.:
    # - Numbers are left-padded with zeroes to achieve natural sort.
    # - Titles are lowercased to achieve case-insensitivity.
    if [Variants::FILE, Variants::DIRECTORY].include?(self.variant)
      # (parent title)-(parent title)-(parent title)-(title)
      key = (all_parents.map{ |it| zero_pad_numbers(it.title.downcase) }.reverse +
          [zero_pad_numbers(self.title.downcase)]).join('-')
    else
      sort_first_token = 'aaa'
      sort_last_token  = 'zzz'
      # Parents: (repository ID)-(variant key)-(page)-(subpage)-(title)
      # Children: (parent ID)-(variant key)-(page)-(subpage)-(title)
      key = sprintf('%s-%s-%s-%s-%s',
              self.parent_repository_id || self.repository_id,
              self.variant.present? ? sort_key_for_variant : sort_first_token,
              self.page_number.present? ? zero_pad_numbers(self.page_number) : sort_last_token,
              self.subpage_number.present? ? zero_pad_numbers(self.subpage_number) : sort_last_token,
              self.title.present? ? zero_pad_numbers(self.title.downcase) : sort_last_token)
    end
    key[0..OpensearchClient::MAX_KEYWORD_FIELD_LENGTH]
  end

  def walk(item, index, &block)
    item.items.each do |subitem|
      index += 1
      yield(subitem, index)
      walk(subitem, index, &block)
    end
  end

  def validate_representative_image_format
    if self.representative_image.present?
      unless Representation::SUPPORTED_IMAGE_FORMATS.include?(self.representative_image.split(".").last)
        errors.add(:representative_image, "is of an unsupported format")
      end
    end
  end

  ##
  # Ensures that instances have a title element.
  #
  def validate_title_exists
    unless self.element(:title)
      errors.add(:elements, "must contain a title element")
    end
  end

  def zero_pad_numbers(str, padding = 16)
    StringUtils.pad_numbers(str, '0', padding)
  end

end
