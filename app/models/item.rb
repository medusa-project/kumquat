##
# Encapsulates a unit of intellectual content.
#
# # Structure
#
# All items reside in a collection. An item may have one or more child items,
# as may any of those, forming a tree. The tree structure depends on the
# collection's package profile. The "free-form" profile allows an arbitrary
# structure; other profiles are more rigid.
#
# An item may also have one or more Binaries, each corresponding to a file in
# Medusa.
#
# # Identifiers
#
# Medusa is not item-aware; items are a DLS entity. Item IDs correspond to
# Medusa file/directory IDs depending on a collection's package profile. These
# IDs are stored in `repository_id`, NOT `id`, which is only used by
# ActiveRecord.
#
# Items have a soft pointer to their collection and parent item based on
# repository ID, rather than a belongs_to/has_many on their database ID.
# This is in order to establish structure outside of the application.
# Repository IDs are the same in all instances of the application that use the
# same Medusa content.
#
# # Description
#
# Items have a number of properties of their own as well as a one-to-many
# relationship with ItemElement, which encapsulates a metadata element.
# Properties are used by the system, and ItemElements contain free-form strings
# and/or URIs.
#
# ## Properties
#
# ### Adding a property:
#
# 1) Add a column for it on Item
# 2) Add it to Item::IndexFields (if it needs to be indexed)
# 3) Add serialization code to as_json() and as_indexed_json()
# 4) Add deserialization code to update_from_json()
# 5) If it needs to appear in TSV, add it to `tsv_columns()`,
#    `ItemTsvExporter`, and/or `update_from_tsv()`
# 6) Update fixtures and tests
# 7) Reindex (if necessary)
#
# ## Descriptive Metadata
#
# The set of elements that an item will contain is shaped by its collection's
# metadata profile, but there is no constraint in place to keep an item from
# being associated with elements not in the profile. This is a safety feature,
# so that deleting an element from a profile does not delete it from any items
# contained in the collections to which the profile is assigned.
#
# # Indexing
#
# Items are searchable via ActiveRecord as well as via Elasticsearch. ES search
# functionality is provided by the elasticsearch-model gem which provides a
# `search` class method. But, in many cases, it's better to use the higher-
# level query interface provided by ItemFinder, which is easier to use, and
# takes authorization, public visiblity, etc. into account.
#
# Instances are automatically indexed in Elasticsearch (see
# `as_indexed_json()`) upon transaction commit. They are **not** indexed on
# save. For this reason, **instances should always be created, updated, and
# deleted within transactions.**
#
# # Attributes
#
# * collection_repository_id: See "Identifiers" above.
# * contentdm_alias:      String collection alias of items that have been
#                         migrated out of CONTENTdm, used for URL redirection.
# * contentdm_pointer:    Integer pointer of items that have been migrated out
#                         of CONTENTdm, used for URL redirection.
# * created_at:           Managed by ActiveRecord.
# * date:                 Normalized date, for date-based queries.
# * embed_tag:            HTML snippet that will be used to display an
#                         alternative object viewer.
# * latitude:             Normalized latitude in decimal degrees.
# * longitude:            Normalized longitude in decimal degrees.
# * page_number:          Literal page number of a page-variant item.
# * parent_repository_id: See "Identifiers" above.
# * published:            Controls public availability. Unpublished items
#                         shouldn't appear in public search results or be
#                         accessible in any other way publicly.
# * repository_id:        See "Identifiers" above.
# * representative_binary_id: Medusa UUID of an alternative binary designated
#                             to stand in as a representation of the item.
# * representative_item_repository_id: Repository ID of another item designated
#                                      to stand in as a representation of the
#                                      item. For example, using a different
#                                      item to provide a thumbnail image for an
#                                      item that is not very photogenic.
# * subpage_number:       Subpage number of a page-variant item. Only used when
#                         there are multiple items corresponding to a single
#                         page of a physical object.
# * updated_at:           Managed by ActiveRecord.
# * variant:              Like a subclass. Used to differentiate types of
#                         items.
#
# @see https://github.com/elastic/elasticsearch-rails/blob/master/elasticsearch-model/README.md
#
class Item < ApplicationRecord

  include AuthorizableByRole
  include Describable
  include Elasticsearch::Model
  include Representable

  class IndexFields
    COLLECTION = 'collection'
    CREATED = 'date_created'
    DATE = 'date'
    DESCRIBED = 'described'
    EFFECTIVE_ALLOWED_ROLE_COUNT = 'effective_allowed_role_count'
    EFFECTIVE_ALLOWED_ROLES = 'effective_allowed_roles'
    EFFECTIVE_DENIED_ROLE_COUNT = 'effective_denied_role_count'
    EFFECTIVE_DENIED_ROLES = 'effective_denied_roles'
    ITEM_SETS = 'item_sets'
    LAST_MODIFIED = 'last_modified'
    LAT_LONG = 'lat_long'
    LAST_INDEXED = 'date_last_indexed'
    # Repository ID of the item, or its parent item, if a child within a
    # compound object.
    OBJECT_REPOSITORY_ID = 'object_repository_id'
    PAGE_NUMBER = 'page_number'
    PARENT_ITEM = 'parent_item'
    PRIMARY_MEDIA_CATEGORY = 'primary_media_category'
    # N.B.: An item might be published but its collection might not be, making
    # it still effectively unpublished. This will take that into account.
    PUBLICLY_ACCESSIBLE = ElasticsearchIndex::PUBLICLY_ACCESSIBLE_FIELD
    PUBLISHED = 'published'
    REPOSITORY_ID = 'repository_id'
    REPRESENTATIVE_FILENAME = 'representative_filename'
    REPRESENTATIVE_ITEM = 'representative_item_id'
    SEARCH_ALL = ElasticsearchIndex::SEARCH_ALL_FIELD
    # Concatenation of various compound object page components or path
    # components (see as_indexed_json()) used for sorting items grouped
    # structurally.
    STRUCTURAL_SORT = 'structural_sort'
    SUBPAGE_NUMBER = 'subpage_number'
    TITLE = ItemElement.new(name: 'title').indexed_keyword_field
    TOTAL_BYTE_SIZE = 'total_byte_size'
    VARIANT = 'variant'
  end

  ##
  # N.B. When modifying these, modify sort_key_for_variant() as well.
  #
  class Variants
    BACK_COVER = 'BackCover'
    COMPOSITE = 'Composite'
    DIRECTORY = 'Directory'
    FILE = 'File'
    FRONT_COVER = 'FrontCover'
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    INSIDE_BACK_COVER = 'InsideBackCover'
    INSIDE_FRONT_COVER = 'InsideFrontCover'
    KEY = 'Key'
    PAGE = 'Page'
    SUPPLEMENT = 'Supplement'
    TABLE_OF_CONTENTS = 'TableOfContents'
    THREE_D_MODEL = '3DModel'
    TITLE = 'Title'

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

  # In the order they should appear in the TSV, left-to-right.
  NON_DESCRIPTIVE_TSV_COLUMNS = %w(uuid parentId preservationMasterPathname
    preservationMasterFilename preservationMasterUUID accessMasterPathname
    accessMasterFilename accessMasterUUID variant pageNumber subpageNumber
    contentdmAlias contentdmPointer IGNORE)

  has_and_belongs_to_many :allowed_roles, class_name: 'Role',
                          association_foreign_key: :allowed_role_id
  has_and_belongs_to_many :denied_roles, class_name: 'Role',
                          association_foreign_key: :denied_role_id
  has_and_belongs_to_many :effective_allowed_roles, class_name: 'Role',
                          association_foreign_key: :effective_allowed_role_id
  has_and_belongs_to_many :effective_denied_roles, class_name: 'Role',
                          association_foreign_key: :effective_denied_role_id
  has_and_belongs_to_many :item_sets

  has_many :binaries, inverse_of: :item, dependent: :destroy
  has_many :elements, class_name: 'ItemElement', inverse_of: :item,
           dependent: :destroy

  belongs_to :representative_binary, class_name: 'Binary'

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
  # representative_item_repository_id
  validates_format_of :representative_item_repository_id,
                      with: StringUtils::UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  # subpage_number
  validates :subpage_number, numericality: { only_integer: true,
                                             greater_than_or_equal_to: 1 },
            allow_blank: true
  # variant
  validates :variant, inclusion: { in: Variants.all }, allow_blank: true

  # ACTIVERECORD CALLBACKS

  before_save :prune_identical_elements, :set_effective_roles,
              :set_normalized_coords, :set_normalized_date
  # This is commented out because, even though it has to happen, it is
  # potentially very time-consuming. It will therefore need to be invoked in a
  # background job whenever instances are updated.
  #after_update :propagate_heritable_properties
  after_commit :index_in_elasticsearch, on: [:create, :update]
  after_commit :delete_from_elasticsearch, on: :destroy

  # Used by the Elasticsearch client for CRUD actions only (not index changes).
  index_name ElasticsearchIndex.current_index(self).name

  ##
  # @return [Integer]
  #
  def self.num_free_form_files
    ItemFinder.new.
        include_variants(*Variants::FILE).
        aggregations(false).
        include_unpublished(true).
        search_children(true).
        count
  end

  ##
  # @return [Integer]
  #
  def self.num_free_form_items
    ItemFinder.new.
        include_variants(Variants::FILE, Variants::DIRECTORY).
        aggregations(false).
        search_children(true).
        include_unpublished(true).
        count
  end

  ##
  # @return [Integer] Number of objects in the database.
  #
  def self.num_objects
    num_free_form_files + ItemFinder.new.
        aggregations(false).
        include_unpublished(true).
        search_children(false).
        exclude_variants(Variants::FILE, Variants::DIRECTORY).
        count
  end

  ##
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def self.reindex_all(index = :current)
    num_items = Item.count
    Item.uncached do
      Item.all.find_each.with_index do |item, i|
        item.reindex(index)

        pct_complete = (i / num_items.to_f) * 100
        puts "Item.reindex_all(): #{pct_complete.round(2)}%"
      end
    end
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
  # @return [Enumerable<Item>] All items that are children of the instance, at
  #                            any level in the tree.
  # @see walk_tree()
  #
  def all_children
    sql = 'WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[repository_id] AS breadcrumb
        FROM items h
        WHERE repository_id = $1
        UNION ALL
        SELECT hi, q.level + 1 AS level, breadcrumb || repository_id
        FROM q
        JOIN items hi
          ON hi.parent_repository_id = (q.h).repository_id
      )
      SELECT (q.h).repository_id
      FROM q
      ORDER BY breadcrumb'
    values = [[ nil, self.repository_id ]]

    results = ActiveRecord::Base.connection.exec_query(sql, 'SQL', values)
    Item.where('repository_id IN (?)', results.map{ |row| row['repository_id'] })
  end

  ##
  # @return [Enumerable<Item>] All items with a variant of Variants::FILE
  #                            that are children of the instance, at any level
  #                            in the tree.
  #
  def all_files
    sql = 'WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[repository_id] AS breadcrumb
        FROM items h
        WHERE repository_id = $1
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
    values = [[ nil, self.repository_id, ], [ nil, Variants::FILE ]]

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
  # N.B.: Changing this normally requires adding a new index schema version.
  #
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json(options = {})
    doc = {}
    search_all_values = []
    doc[IndexFields::COLLECTION] = self.collection_repository_id
    doc[IndexFields::DATE] = self.date.utc.iso8601 if self.date
    doc[IndexFields::DESCRIBED] = self.described?

    doc[IndexFields::EFFECTIVE_ALLOWED_ROLES] =
        self.effective_allowed_roles.pluck(:key)
    doc[IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT] =
        doc[IndexFields::EFFECTIVE_ALLOWED_ROLES].length
    doc[IndexFields::EFFECTIVE_DENIED_ROLES] =
        self.effective_denied_roles.pluck(:key)
    doc[IndexFields::EFFECTIVE_DENIED_ROLE_COUNT] =
        doc[IndexFields::EFFECTIVE_DENIED_ROLES].length
    doc[IndexFields::ITEM_SETS] = self.item_sets.pluck(:id)
    doc[IndexFields::LAST_INDEXED] = Time.now.utc.iso8601
    if self.latitude and self.longitude
      doc[IndexFields::LAT_LONG] = { lon: self.longitude, lat: self.latitude }
    end
    doc[IndexFields::OBJECT_REPOSITORY_ID] = self.collection.free_form? ?
                                                 self.repository_id :
                                                 (self.parent_repository_id || self.repository_id)
    doc[IndexFields::PAGE_NUMBER] = self.page_number
    doc[IndexFields::PARENT_ITEM] = self.parent_repository_id
    doc[IndexFields::PRIMARY_MEDIA_CATEGORY] = self.primary_media_category
    doc[IndexFields::PUBLICLY_ACCESSIBLE] = self.publicly_accessible?
    doc[IndexFields::PUBLISHED] = self.published
    doc[IndexFields::REPOSITORY_ID] = self.repository_id
    doc[IndexFields::REPRESENTATIVE_FILENAME] = self.representative_filename
    doc[IndexFields::REPRESENTATIVE_ITEM] = self.representative_item_repository_id
    doc[IndexFields::STRUCTURAL_SORT] = structural_sort_key
    doc[IndexFields::SUBPAGE_NUMBER] = self.subpage_number
    doc[IndexFields::TOTAL_BYTE_SIZE] = self.binaries.pluck(:byte_size).sum
    doc[IndexFields::VARIANT] = self.variant

    # Index metadata elements into dynamic fields.
    self.elements.each do |element|
      # ES will automatically create a one or more multi fields for this.
      # See: https://www.elastic.co/guide/en/elasticsearch/reference/0.90/mapping-multi-field-type.html
      doc[element.indexed_field] = element.value[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]

      # If the element is searchable in the collection's metadata profile, or
      # if the collection doesn't have a metadata profile, add its value to the
      # search-all field.
      if !self.collection.metadata_profile or
          self.collection.metadata_profile.elements.
              select{ |mpe| mpe.name == element.name }.first&.searchable
        search_all_values << doc[element.indexed_field]
      end
    end

    # We also need to index parent metadata fields. These are needed when we
    # want to find parents matching a query, and include them and all of their
    # children in results.
    if self.parent
      self.parent.elements.each do |element|
        doc[element.parent_indexed_field] = element.value[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
      end
    end

    doc[IndexFields::SEARCH_ALL] = search_all_values.join(' ')

    doc
  end

  ##
  # N.B.: This method must be kept in sync with update_from_json().
  #
  # @return [Hash] Complete JSON representation of the instance. This may
  #                include private information that is not appropriate for
  #                public consumption.
  #
  def as_json(options = {})
    struct = super(options)
    struct['date'] = self.date&.utc&.iso8601
    # Add children
    struct['children'] = []
    self.items.each { |it| struct['children'] << it.as_json.select{ |k, v| k == 'repository_id' } }
    # Add binaries
    struct['binaries'] = []
    self.binaries.each { |b| struct['binaries'] << b.as_json.except(:item_id) }
    # Add ItemElements
    struct['elements'] = []
    self.elements.each { |e| struct['elements'] << e.as_json }
    struct
  end

  ##
  # @return [String, nil] Value of the bibId element.
  #
  def bib_id
    self.element(:bibId)&.value
  end

  ##
  # @return [String, nil] URL of the instance in the library OPAC. Will be
  #                       non-nil only if the instance's bib ID is non-nil.
  #
  def catalog_record_url
    bibid = self.bib_id
    bibid.present? ?
        "http://vufind.carli.illinois.edu/vf-uiu/Record/uiu_#{bibid}" : nil
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
  # @return [String]
  # @see http://dublincore.org/documents/dcmi-type-vocabulary/#H7
  #
  def dc_type
    self.is_compound? ? 'Collection' : self.effective_viewer_binary&.dc_type
  end

  ##
  # An item is considered described if it has any elements other than `title`,
  # or is in a collection using the free-form package profile.
  #
  # @return [Boolean]
  #
  def described?
    if self.collection.free_form?
      return ((self.variant == Variants::DIRECTORY) or
          self.elements.select{ |e| e.name == 'title' }.any?)
    else
      return self.elements.reject{ |e| e.name == 'title' }.any?
    end
  end

  ##
  # @return [Boolean] Whether the variant is Variants::DIRECTORY.
  #
  def directory?
    self.variant == Variants::DIRECTORY
  end

  ##
  # Returns the best binary to use with an IIIF image server, guaranteed to be
  # compatible with it, in the following order of preference:
  #
  # 1. The representative binary
  # 2. If the instance's variant is `SUPPLEMENT`, any binary
  # 3. If the instance is compound, the `effective_image_binary()` of the
  #    first child, sorted structurally
  # 4. Any access master of `Binary::MediaCategory::IMAGE`
  # 5. Any access master of `Binary::MediaCategory::VIDEO`
  # 6. Any access master with media type `application/pdf`
  # 7. Any preservation master of `Binary::MediaCategory::IMAGE`
  # 8. Any preservation master of `Binary::MediaCategory::VIDEO`
  # 9. Any preservation master with media type `application/pdf`
  #
  # @return [Binary, nil]
  # @see effective_viewer_binary()
  #
  def effective_image_binary
    unless @effective_image_binary
      bin = self.representative_binary
      if !bin or !bin.iiif_safe?
        if self.variant == Variants::SUPPLEMENT
          bin = self.binaries.first
        elsif self.is_compound?
          #bin = self.finder.limit(1).to_a.first&.effective_image_binary # TODO: prevent a circular reference
        end
        if !bin or !bin.iiif_safe?
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
              b.master_type == pref[:master_type] and
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
  # Returns the instance's effective representative item based on the following
  # order of preference:
  #
  # 1. The instance's assigned representative item (if it has one)
  # 2. The instance's first page (if it has any)
  # 3. The instance's first child item (if it has any)
  # 4. The instance itself
  #
  # @return [Item]
  # @see representative_item
  #
  def effective_representative_entity
    self.representative_item ||
        self.items.where(variant: Variants::FRONT_COVER).first ||
        self.items.where(variant: Variants::TITLE).first ||
        self.pages.limit(1).to_a.first ||
        self
  end

  alias_method :effective_representative_image_binary, :effective_image_binary

  ##
  # @return [String, nil] Rights statement assigned to the instance, if
  #                       present; otherwise, the closest ancestor statement,
  #                       if present; otherwise, the rights statement assigned
  #                       to its collection, if present; otherwise nil.
  #
  def effective_rights_statement
    # Use the statement assigned to the instance.
    rs = self.elements.select{ |e| e.name == 'rights' and e.value.present? }.
        first&.value
    # If not available, walk up the item tree to find a parent statement.
    if rs.blank?
      p = self.parent
      while p
        rs = p.elements.select{ |e| e.name == 'rights' and e.value.present? }.
            first&.value
        break if rs.present?
        p = p.parent
      end
    end
    # If still no statement available, use the collection's statement.
    rs = self.collection.rights_statement if rs.blank?
    rs
  end

  ##
  # @return [RightsStatement, nil] RightsStatements.org statement assigned to
  #                                the instance, if present; otherwise, the
  #                                closest ancestor statement, if present;
  #                                otherwise, the statement assigned to its
  #                                collection, if present; otherwise nil.
  # @see rightsstatements_org_statement()
  #
  def effective_rightsstatements_org_statement
    # Use the statement assigned to the instance.
    uri = self.elements.select{ |e| e.name == 'accessRights' and
        e.uri&.start_with?('http://rightsstatements.org') }.first&.uri
    rs = RightsStatement.for_uri(uri)
    # If not assigned, walk up the item tree to find a parent statement.
    unless rs
      p = self.parent
      while p
        uri = p.elements.select{ |e| e.name == 'accessRights' and
            e.uri&.start_with?('http://rightsstatements.org') }.first&.uri
        rs = RightsStatement.for_uri(uri)
        break if rs
        p = p.parent
      end
    end
    # If still no statement available, use the collection's statement.
    rs = RightsStatement.for_uri(self.collection.rightsstatements_org_uri) unless rs
    rs
  end

  ##
  # Returns the best binary to use for a main viewer. It may or may not be an
  # image.
  #
  # 1. The representative binary
  # 2. If the instance's variant is `SUPPLEMENT`, any binary
  # 3. If the instance is compound, the `effective_image_binary()` of the
  #    first child, sorted structurally
  # 4. Any access master of `Binary::MediaCategory::IMAGE`
  # 5. Any other access master
  # 6. Any preservation master of `Binary::MediaCategory::IMAGE`
  # 7. Any other preservation master
  #
  # @return [Binary, nil]
  # @see effective_image_binary()
  #
  def effective_viewer_binary
    unless @effective_viewer_binary
      bin = self.representative_binary
      if !bin or !bin.iiif_safe?
        if self.variant == Variants::SUPPLEMENT
          bin = self.binaries.first
        elsif self.is_compound?
          bin = self.finder.limit(1).to_a.first&.effective_image_binary
        end
        if !bin or !bin.iiif_safe?
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
            bin = self.binaries.select do |b|
              b.master_type == pref[:master_type] and
                  (pref[:media_category] ?
                       (b.media_category == pref[:media_category]) : true)
            end
            bin = bin.first
            break if bin
          end
        end
      end
      @effective_viewer_binary = bin
    end
    @effective_viewer_binary
  end

  ##
  # @param options [Hash]
  # @option options [Boolean] :only_visible
  # @return [Enumerable<ItemElement>] The instance's ItemElements in the order
  #                                   of the elements in the collection's
  #                                   metadata profile.
  #
  def elements_in_profile_order(options = {})
    all_elements = []
    mp_elements = self.collection.metadata_profile.elements
    if options[:only_visible]
      mp_elements = mp_elements.where(visible: true)
    end
    mp_elements.each do |mpe|
      all_elements += self.elements.select{ |e| e.name == mpe.name }
    end
    all_elements
  end

  ##
  # @return [Boolean] Whether the variant is Variants::FILE.
  #
  def file?
    self.variant == Variants::FILE
  end

  ##
  # @return [Boolean]
  #
  def has_iiif_manifest?
    self.is_compound? or
        [Variants::DIRECTORY, Variants::FILE].include?(self.variant) or
        !self.variant
  end

  ##
  # @return [Boolean] Whether the instance has any children with a "page"
  #                   variant.
  #
  def is_compound?
    self.variant.blank? and self.pages.count > 0
  end

  ##
  # @param recursive [Boolean] Whether to include all items regardless of depth
  #                            in the hierarchy, or only immediate children.
  # @return [Enumerable<Item>] Child items.
  #
  def items(recursive = false)
    items = []
    if recursive
      def all_items(bucket, child_items)
        child_items.each do |child|
          bucket << child
          all_items(bucket, child.items(false))
        end
        bucket
      end
      items = all_items(items, self.items(false))
    else
      items = Item.where(parent_repository_id: self.repository_id)
    end
    items
  end

  ##
  # @return [ItemFinder] ItemFinder initialized to search for child items.
  #
  def finder
    ItemFinder.new.
        parent_item(self).
        aggregations(false).
        include_children_in_results(true).
        search_children(true).
        order(Item::IndexFields::STRUCTURAL_SORT)
  end

  ##
  # Transactionally migrates elements with the given source name to new
  # elements with the given destination name, and then deletes the source
  # elements.
  #
  # Call reload() afterwards to refresh the `elements` relationship.
  #
  # @param source_name [String] Source element name
  # @param dest_name [String] Destination element name
  # @return [void]
  #
  def migrate_elements(source_name, dest_name)
    ActiveRecord::Base.transaction do
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

  ##
  # @return [ItemFinder] ItemFinder initialized to return all children with a
  #                      variant of Variants::PAGE.
  #
=begin
  def pages TODO: why is this so slow?
    self.finder.include_variants(Variants::PAGE).
        order(IndexFields::PAGE_NUMBER).
        order(IndexFields::SUBPAGE_NUMBER)
  end
=end

  ##
  # @return [ActiveRecord::Relation<Item>] All children with a variant of
  #                                        Variants::PAGE.
  #
  def pages
    self.items.where(variant: Variants::PAGE).
        order(IndexFields::PAGE_NUMBER => :asc).
        order(IndexFields::SUBPAGE_NUMBER => :asc)
  end

  ##
  # @return [Item, nil]
  # @see all_parents()
  #
  def parent
    @parent = Item.find_by_repository_id(self.parent_repository_id) unless @parent
    @parent
  end

  ##
  # Infers the primary media category of the instance by analyzing its
  # binaries' media categories.
  #
  # @return [Integer, nil] One of the `Binary::MediaCategory` constant values.
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
  # Propagates roles from the instance to all of its children. This is an O(n)
  # operation.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_heritable_properties(task = nil)
    ActiveRecord::Base.transaction do
      num_items = self.items.count

      self.walk_tree do |item, index|
        # Propagation will be carried out in before_save callbacks.
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  ##
  # @return [Boolean] Whether the instance and its collection are both
  #                   publicly accessible.
  #
  def publicly_accessible?
    self.published and self.collection.publicly_accessible?
  end

  ##
  # @param index [Symbol] :current or :latest
  # @return [void]
  #
  def reindex(index = :current)
    index_in_elasticsearch(index)
  end

  ##
  # @return [String]
  #
  def representative_filename
    bin = self.binaries.where('repository_relative_pathname IS NOT NULL').
        where('media_category != ?', Binary::MediaCategory::THREE_D).
        order(:master_type).limit(1).first
    bin&.filename&.split('.')&.first
  end

  ##
  # @return [Item, nil] The instance's assigned representative item, which may
  #                     be nil. For the purposes of getting "the"
  #                     representative item, `effective_representative_entity`
  #                     should be used instead.
  # @see effective_representative_entity
  #
  def representative_item
    Item.find_by_repository_id(self.representative_item_repository_id)
  end

  ##
  # @return [RightsStatement, nil]
  # @see effective_rightsstatements_org_statement()
  #
  def rightsstatements_org_statement
    RightsStatement.for_uri(self.element(:accessRights)&.uri)
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

  ##
  # @return [Element]
  #
  def title
    t = self.element(:title)&.value
    t.present? ? t : self.repository_id
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
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :include_date_created
  # @raises [IOError]
  #
  def update_from_embedded_metadata(options = {})
    return unless self.binaries.any?

    ActiveRecord::Base.transaction do
      self.elements.destroy_all
      self.elements += elements_from_embedded_metadata(options)
      self.save!
    end
  end

  ##
  # Updates an instance from a JSON representation compatible with the structure
  # returned by as_json().
  #
  # N.B.: This method must be kept in sync with as_json().
  #
  # @param json [String]
  # @return [void]
  # @raises [ArgumentError]
  #
  def update_from_json(json)
    struct = JSON.parse(json)
    ActiveRecord::Base.transaction do
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
      # repository_id is not modifiable
      self.representative_item_repository_id =
          struct['representative_item_repository_id']
      self.subpage_number = struct['subpage_number']
      # updated_at is not modifiable
      self.variant = struct['variant']

      # ELEMENTS
      # Current elements need to be deleted first, otherwise it would be
      # impossible for an update to remove them.
      self.elements.destroy_all

      if struct['elements'].respond_to?(:each)
        struct['elements'].each do |se|
          # Add a new element
          ie = ItemElement.named(se['name'])
          if ie
            ie.uri = se['uri']&.strip
            ie.value = se['string']&.strip
            ie.vocabulary = Vocabulary.find_by_key(se['vocabulary'])
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
  #                         element name
  # @raises [ArgumentError] If a column heading contains an unrecognized
  #                         vocabulary prefix
  #
  def update_from_tsv(row)
    ActiveRecord::Base.transaction do
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

      # variant
      self.variant = row['variant'].strip if row['variant']

      # Descriptive metadata elements.
      row.each do |heading, raw_value|
        # Vocabulary columns will have a heading of "vocabKey:elementLabel",
        # except uncontrolled columns which will have a heading of just
        # "elementLabel".
        heading_parts = heading.to_s.split(':')
        element_label = heading_parts.last
        element_name = self.collection.metadata_profile.elements.
            select{ |e| e.label == element_label }.first&.name

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
  # Accepts a block to perform on the instance and all subitems in the tree.
  #
  def walk_tree(&block)
    index = 0
    yield(self, index)
    walk(self, index, &block)
  end

  private

  def delete_from_elasticsearch
    logger = CustomLogger.instance
    begin
      logger.debug(['Deleting document... ',
                    __elasticsearch__.delete_document].join)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      logger.warn("Item.delete_from_elasticsearch(): #{e}")
    end
  end

  def elements_for_iim_value(iim_elem_label, dest_elem, iim_metadata)
    src_elem = iim_metadata.select{ |e| e[:label] == iim_elem_label }.first
    src_elem ? elements_for_value(src_elem[:value], dest_elem) : []
  end

  ##
  # @param value [String,Enumerable]
  # @param dest_elem [String]
  # @return [ItemElement]
  #
  def elements_for_value(value, dest_elem)
    value = [value] unless value.respond_to?(:each)
    # "-" is a junk value that has been known to exist in our IPTC metadata.
    value.select{ |v| v.present? and v != '-' }.map do |val|
      ItemElement.new(name: dest_elem, value: val,
                      vocabulary: Vocabulary.uncontrolled)
    end
  end

  ##
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :include_date_created
  # @return [Enumerable<ItemElement>]
  #
  def elements_from_embedded_metadata(options = {})
    elements = []

    # Get the binary from which the metadata will be extracted.
    # First, try to get the preservation master image.
    bs = self.binaries.select{ |b| b.master_type == Binary::MasterType::PRESERVATION and
        b.media_category == Binary::MediaCategory::IMAGE }.first
    # If that wasn't available, try to get any image.
    unless bs
      bs = self.binaries.select{ |b| b.media_category == Binary::MediaCategory::IMAGE }.first
      unless bs
        CustomLogger.instance.
            info('Item.elements_from_embedded_metadata(): no binaries')
        return elements
      end
    end

    CustomLogger.instance.debug("Item.elements_from_embedded_metadata: using "\
        "#{bs.human_readable_master_type} (#{bs.absolute_local_pathname})")

    # Get its embedded IIM metadata
    iim_metadata = bs.metadata.select{ |m| m[:category] == 'IPTC' }

    # See discussion in IMET-246
    # See: https://docs.google.com/spreadsheets/d/15Wf75vzP-rW-lrYzLHATjv1bI3xcMMSVbdBShy4t55A/edit
    # See: http://www.iptc.org/std/photometadata/specification/IPTC-PhotoMetadata

    # Title
    # Hack to treat items in a particular collection differently (IMET-397)
    if self.collection_repository_id == '8838a520-2b19-0132-3314-0050569601ca-7'
      title = { value: File.basename(bs.repository_relative_pathname) }
    else
      title = iim_metadata.select{ |e| e[:label] == 'Headline' }.first
      unless title
        title = iim_metadata.select{ |e| e[:label] == 'Title' }.first
        unless title
          title = iim_metadata.select{ |e| e[:label] == 'Object Name' }.first
        end
      end
    end
    elements += elements_for_value(title[:value], 'title') if title

    # Date Created
    if options[:include_date_created].to_s != 'false'
      elements += elements_for_iim_value('Date Created', 'dateCreated', iim_metadata)
    end

    # Creator
    creator = iim_metadata.select{ |e| e[:label] == 'Creator' }.first
    unless creator
      creator = iim_metadata.select{ |e| e[:label] == 'By-line' }.first
      unless creator
        creator = iim_metadata.select{ |e| e[:label] == 'Credit Line' }.first
      end
    end
    elements += elements_for_value(creator[:value], 'creator') if creator

    # Description
    desc = iim_metadata.select{ |e| e[:label] == 'Description' }.first
    unless desc
      desc = iim_metadata.select{ |e| e[:label] == 'Caption' }.first
      unless desc
        desc = iim_metadata.select{ |e| e[:label] == 'Abstract' }.first
      end
    end
    elements += elements_for_value(desc[:value], 'description') if desc

    # Copyright Notice
    elements += elements_for_iim_value('Copyright Notice', 'rights', iim_metadata)

    # Rights Usage Terms
    elements += elements_for_iim_value('Rights Usage Terms', 'license', iim_metadata)

    # Keywords
    elements += elements_for_iim_value('Keywords', 'keyword', iim_metadata)

    # Sublocation
    elements += elements_for_iim_value('Sublocation', 'streetAddress', iim_metadata)

    # City
    elements += elements_for_iim_value('City', 'addressLocality', iim_metadata)

    # Province or State
    elements += elements_for_iim_value('Province or State', 'addressRegion', iim_metadata)

    # Country Name
    elements += elements_for_iim_value('Country Name', 'addressCountry', iim_metadata)

    # Copy sublocation, city, province or state, and country name into keyword
    # elements.

    elements += elements_for_iim_value('Sublocation', 'keyword', iim_metadata)
    elements += elements_for_iim_value('City', 'keyword', iim_metadata)
    elements += elements_for_iim_value('Province or State', 'keyword', iim_metadata)
    elements += elements_for_iim_value('Country Name', 'keyword', iim_metadata)

    elements
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

  ##
  # @return [void]
  #
  def inherit_roles
    allowed_roles = []
    denied_roles = []
    # Try to inherit from an ancestor.
    p = self.parent
    while p
      allowed_roles = p.allowed_roles
      denied_roles = p.denied_roles
      break if allowed_roles.any? or denied_roles.any?
      p = p.parent
    end
    # If no ancestor has any roles, inherit from the collection.
    if allowed_roles.empty? and denied_roles.empty?
      allowed_roles = self.collection.allowed_roles
      denied_roles = self.collection.denied_roles
    end

    ActiveRecord::Base.transaction do
      self.effective_allowed_roles.destroy_all
      self.effective_denied_roles.destroy_all
      allowed_roles.each do |role|
        self.effective_allowed_roles << role
      end
      denied_roles.each do |role|
        self.effective_denied_roles << role
      end
    end
  end

  ##
  # Removes duplicate elements, ensuring that all are unique.
  #
  def prune_identical_elements
    ActiveRecord::Base.transaction do
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
  # Populates effective_allowed_roles and effective_denied_roles.
  #
  # @return [void]
  #
  def set_effective_roles
    allowed_roles = self.allowed_roles
    denied_roles = self.denied_roles
    if allowed_roles.any? or denied_roles.any?
      ActiveRecord::Base.transaction do
        self.effective_allowed_roles.destroy_all
        self.effective_denied_roles.destroy_all
        allowed_roles.each do |role|
          self.effective_allowed_roles << role
        end
        denied_roles.each do |role|
          self.effective_denied_roles << role
        end
      end
    else
      inherit_roles
    end
  end

  ##
  # Tries to set the normalized latitude/longitude from a `coordinates` element.
  #
  def set_normalized_coords
    coords_elem = self.element(:coordinates)
    if coords_elem
      coords = SpaceUtil.string_coordinates_to_coordinates(coords_elem.value)
      if coords
        self.latitude = coords[:latitude]
        self.longitude = coords[:longitude]
      end
    end
  end

  ##
  # Tries to set the normalized date from a `date` or `dateCreated` element.
  #
  def set_normalized_date
    date_elem = self.element(:date) || self.element(:dateCreated)
    if date_elem
      self.date = TimeUtil.string_date_to_time(date_elem.value)
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
      sort_last_token = 'zzz'
      # Parents: (repository ID)-(variant key)-(page)-(subpage)-(title)
      # Children: (parent ID)-(variant key)-(page)-(subpage)-(title)
      key = sprintf('%s-%s-%s-%s-%s',
              self.parent_repository_id || self.repository_id,
              self.variant.present? ? sort_key_for_variant : sort_first_token,
              self.page_number.present? ? zero_pad_numbers(self.page_number) : sort_last_token,
              self.subpage_number.present? ? zero_pad_numbers(self.subpage_number) : sort_last_token,
              self.title.present? ? zero_pad_numbers(self.title.downcase) : sort_last_token)
    end
    key[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
  end

  def walk(item, index, &block)
    item.items.each do |subitem|
      index += 1
      yield(subitem, index)
      walk(subitem, index, &block)
    end
  end

  def zero_pad_numbers(str, padding = 16)
    str.to_s.gsub(/\d+/) { |match| match.rjust(padding, '0') }
  end

end
