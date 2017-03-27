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
# IDs are stored in `repository_id`, NOT `id`, which is only used internally by
# ActiveRecord.
#
# Items have a soft pointer to their collection and parent item based on
# repository ID, rather than a belongs_to/has_many on their database ID.
# This is to be able to establish structure outside of the application.
# Repository IDs are the same in all instances of the application.
#
# # Description
#
# Items have a number of properties of their own as well as a one-to-many
# relationship with ItemElement, which encapsulates a metadata element.
# Properties are used/needed by the system, and ItemElements are basically
# free-form strings.
#
# ## Properties
#
# ### Adding a property:
#
# 1) Add a column for it on Item
# 2) Add it to Item::SolrFields
# 3) Add serialization code to Item.tsv_header, as_json, to_solr, and
#    Collection.items_as_tsv
# 4) Add deserialization code to Item.update_from_json and update_from_tsv
# 5) Update fixtures and tests
# 6) Reindex (if necessary)
#
# ## Descriptive Metadata
#
# The set of elements that an item contains is typically shaped by its
# collection's metadata profile, although there is no constraint in place to
# keep an item from being associated with elements not in the profile.
#
# # Indexing
#
# Items are searchable via ActiveRecord as well as via Solr (see ItemFinder).
# The Solr search functionality is available via the `solr` class method.
#
# Instances are automatically indexed in Solr (see `to_solr`) upon transaction
# commital. They are **not** indexed on save. For this reason, **instances
# should only be updated within a transaction.**
#
class Item < ActiveRecord::Base

  include AuthorizableByRole
  include Describable
  include SolrQuerying

  class SolrFields
    CLASS = 'class_si'
    COLLECTION = 'collection_si'
    # The owning collection's published status is stored to expedite queries.
    # Naturally, when it changes, its items will need to be reindexed.
    COLLECTION_PUBLISHED = 'collection_published_bi'
    CREATED = 'created_dti'
    DATE = 'date_dti'
    EFFECTIVE_ALLOWED_ROLES = 'effective_allowed_roles_sim'
    EFFECTIVE_DENIED_ROLES = 'effective_denied_roles_sim'
    FULL_TEXT = 'full_text_txti'
    # Concatenation of various compound object page components or path
    # components (see to_solr()) used for sorting items grouped structurally.
    GROUPED_SORT = 'grouped_sort_natsort_en_i'
    ID = 'id'
    LAST_MODIFIED = 'last_modified_dti'
    LAT_LONG = 'lat_long_loc'
    LAST_INDEXED = 'last_indexed_dti'
    PAGE_NUMBER = 'page_number_ii'
    PARENT_ITEM = 'parent_item_si'
    PRIMARY_MEDIA_CATEGORY = 'primary_media_category_ii'
    PUBLISHED = 'published_bi'
    REPRESENTATIVE_ITEM_ID = 'representative_item_id_si'
    SEARCH_ALL = 'searchall_natsort_en_im'
    SUBPAGE_NUMBER = 'subpage_number_ii'
    TITLE = 'title_natsort_en_i'
    TOTAL_BYTE_SIZE = 'total_byte_size_li'
    VARIANT = 'variant_si'
  end

  class Variants
    COMPOSITE = 'Composite'
    DIRECTORY = 'Directory'
    FILE = 'File'
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    KEY = 'Key'
    PAGE = 'Page'
    SUPPLEMENT = 'Supplement'
    TABLE_OF_CONTENTS = 'TableOfContents'
    TITLE = 'Title'

    ##
    # @return [Enumerable<String>] String values of all variants.
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  # In the order they should appear in the TSV, left-to-right.
  NON_DESCRIPTIVE_TSV_COLUMNS = %w(uuid parentId preservationMasterPathname
    preservationMasterFilename accessMasterPathname accessMasterFilename
    variant pageNumber subpageNumber latitude longitude contentdmAlias
    contentdmPointer)
  TSV_LINE_BREAK = "\n"
  TSV_MULTI_VALUE_SEPARATOR = '||'
  TSV_URI_VALUE_SEPARATOR = '&&'
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  has_and_belongs_to_many :allowed_roles, class_name: 'Role',
                          association_foreign_key: :allowed_role_id
  has_and_belongs_to_many :denied_roles, class_name: 'Role',
                          association_foreign_key: :denied_role_id
  has_and_belongs_to_many :effective_allowed_roles, class_name: 'Role',
                          association_foreign_key: :effective_allowed_role_id
  has_and_belongs_to_many :effective_denied_roles, class_name: 'Role',
                          association_foreign_key: :effective_denied_role_id

  has_many :binaries, inverse_of: :item, dependent: :destroy
  has_many :elements, class_name: 'ItemElement', inverse_of: :item,
           dependent: :destroy

  belongs_to :representative_binary, class_name: 'Binary'

  # VALIDATIONS

  # collection_repository_id
  validates_format_of :collection_repository_id, with: UUID_REGEX,
                      message: 'UUID is invalid'
  # latitude
  validates :latitude, numericality: { greater_than_or_equal_to: -90,
                                       less_than_or_equal_to: 90 },
            allow_blank: true
  # longitude
  validates :longitude, numericality: { greater_than_or_equal_to: -180,
                                        less_than_or_equal_to: 180 },
            allow_blank: true
  # page_number
  validates :page_number, numericality: { only_integer: true,
                                          greater_than_or_equal_to: 1 },
            allow_blank: true
  # parent_repository_id
  validates_format_of :parent_repository_id, with: UUID_REGEX,
                      message: 'UUID is invalid', allow_blank: true
  # repository_id
  validates_format_of :repository_id, with: UUID_REGEX,
                      message: 'UUID is invalid'
  # representative_item_repository_id
  validates_format_of :representative_item_repository_id, with: UUID_REGEX,
                      message: 'UUID is invalid', allow_blank: true
  # subpage_number
  validates :subpage_number, numericality: { only_integer: true,
                                             greater_than_or_equal_to: 1 },
            allow_blank: true
  # variant
  validates :variant, inclusion: { in: Variants.all }, allow_blank: true

  # ACTIVERECORD CALLBACKS

  before_save :prune_identical_elements, :set_effective_roles,
              :set_normalized_coords, :set_normalized_date
  after_update :propagate_roles
  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

  def self.num_free_form_items
    sql = "SELECT COUNT(items.id) AS count
      FROM items
      LEFT JOIN collections
      ON collections.repository_id = items.collection_repository_id
      WHERE collections.package_profile_id = #{PackageProfile::FREE_FORM_PROFILE.id}
      AND items.variant = '#{Item::Variants::FILE}'"
    result = ActiveRecord::Base.connection.execute(sql)
    result[0]['count'].to_i
  end

  ##
  # @return [Integer] Number of objects in the instance.
  #
  def self.num_objects
    sql = "SELECT COUNT(items.id) AS count
      FROM items
      LEFT JOIN collections
      ON collections.repository_id = items.collection_repository_id
      WHERE collections.package_profile_id != #{PackageProfile::FREE_FORM_PROFILE.id}
      AND items.variant IS NULL"
    result = ActiveRecord::Base.connection.execute(sql)
    result[0]['count'].to_i + num_free_form_items
  end

  ##
  # Returns a tab-separated list of applicable technical elements, plus one
  # column per element definition in the item's collection's metadata profile.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [String] Tab-separated values with trailing newline.
  #
  def self.tsv_header(metadata_profile)
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
    columns.join("\t") + TSV_LINE_BREAK
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
  # This method must be kept in sync with update_from_json().
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
    self.elements.select{ |e| e.name == 'bibId' }.first&.value
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
  # @param collection [Collection]
  #
  def collection=(collection)
    self.collection_repository_id = collection.repository_id
  end

  ##
  # @return [Item]
  #
  def composite_item
    self.items.where(variant: Variants::COMPOSITE).limit(1).first
  end

  ##
  # @return [String]
  # @see http://dublincore.org/documents/dcmi-type-vocabulary/#H7
  #
  def dc_type
    type = nil
    # TODO: Software
    if self.is_compound?
      type = 'Collection'
    else
      binary = self.effective_viewer_binary
      if binary
        if binary.is_image?
          type = 'StillImage'
        elsif binary.is_video?
          type = 'MovingImage'
        elsif binary.is_audio?
          type = 'Sound'
        elsif binary.is_pdf? or binary.is_text?
          type = 'Text'
        end
      end
    end
    type
  end

  def delete_from_solr # TODO: change to Item.solr.delete()
    Solr.instance.delete(self.solr_id)
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
  def effective_representative_item
    self.representative_item || self.pages.first || self
  end

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
  # Returns the binary best suited for a primary viewer (image, video, audio,
  # etc.) in the following order of preference:
  #
  # 1. The representative binary
  # 2. If the instance's variant is SUPPLEMENT, any binary
  # 3. Any access master of Binary::MediaCategory::IMAGE
  # 4. Any access master
  # 5. Any preservation master of Binary::MediaCategory::IMAGE
  # 6. Any preservation master
  #
  # @return [Binary, nil]
  #
  def effective_viewer_binary
    bin = self.representative_binary
    unless bin
      if self.variant == Variants::SUPPLEMENT
        bin = self.binaries.first
      end
      unless bin
        bin = self.binaries.
            select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER and
            b.media_category == Binary::MediaCategory::IMAGE }.first
        unless bin
          bin = self.binaries.
              select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER }.first
          unless bin
            bin = self.binaries.
                select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER and
                b.media_category == Binary::MediaCategory::IMAGE }.first
            unless bin
              bin = self.binaries.
                  select{ |b| b.media_category == Binary::MediaCategory::IMAGE }.first
            end
          end
        end
      end
    end
    bin
  end

  ##
  # Queries the database to obtain a Relation of all children that have a
  # variant of Variant::FILE or Variant::DIRECTORY.
  #
  # @return [Relation]
  # @see files_from_solr()
  #
  def files
    self.items.where(variant: [Variants::FILE, Variants::DIRECTORY])
  end

  ##
  # Queries Solr to obtain a Relation of all children that have a
  # variant of Variant::FILE or Variant::DIRECTORY.
  #
  # @return [Relation]
  # @see files()
  #
  def files_from_solr
    Item.solr.where(Item::SolrFields::PARENT_ITEM => self.repository_id).
        where("(#{Item::SolrFields::VARIANT}:#{Item::Variants::FILE} OR "\
            "#{Item::SolrFields::VARIANT}:#{Item::Variants::DIRECTORY})")
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def front_matter_item
    self.items.where(variant: Variants::FRONT_MATTER).limit(1).first
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
  # Returns the best binary to use with an IIIF image server, guaranteed to be
  # compatible with it, in the following order of preference:
  #
  # 1. The representative binary
  # 2. If the instance's variant is SUPPLEMENT, any binary
  # 3. If the instance is compound, the iiif_image_binary of the first page
  # 4. Any access master of Binary::MediaCategory::IMAGE
  # 5. Any access master with media type "application/pdf"
  # 6. Any preservation master of Binary::MediaCategory::IMAGE
  #
  # @return [Binary, nil]
  #
  def iiif_image_binary
    bin = self.representative_binary
    if !bin or !bin.iiif_safe?
      if self.variant == Variants::SUPPLEMENT
        bin = self.binaries.first
      elsif self.is_compound?
        bin = self.pages.first&.iiif_image_binary
      end
      if !bin or !bin.iiif_safe?
        bin = self.binaries.
            select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER and
            b.media_category == Binary::MediaCategory::IMAGE }.first
        if !bin or !bin.iiif_safe?
          bin = self.binaries.
              select{ |b| b.binary_type == Binary::Type::ACCESS_MASTER and
              b.media_type == 'application/pdf' }.first
          if !bin or !bin.iiif_safe?
            bin = self.binaries.
                select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER and
                b.media_category == Binary::MediaCategory::IMAGE }.first
            if !bin or !bin.iiif_safe?
              bin = nil
            end
          end
        end
      end
    end
    bin
  end

  ##
  # @return [void]
  #
  def index_in_solr
    Solr.instance.add(self.to_solr)
    # To improve performance, we will avoid saving here, as this will be
    # called in an after_commit callback 99.99% of the time.
  end

  ##
  # @return [Item] The item's index item, if available.
  #
  def index_item
    self.items.where(variant: Variants::INDEX).limit(1).first
  end

  ##
  # @return [Boolean] Whether the instance has any children with a "page"
  #                   variant.
  #
  def is_compound?
    self.pages.count > 0
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
  # Queries Solr to obtain a Relation of all children.
  #
  # @return [Relation<Item>]
  #
  def items_from_solr
    Item.solr.where(Item::SolrFields::PARENT_ITEM => self.repository_id)
  end

  ##
  # If any child items have a page number, orders by that. Otherwise, orders
  # by title. (IMET-414)
  #
  # @return [Relation<Item>] Subitems in the order they should appear in an
  #                          IIIF presentation API canvas.
  #
  def items_in_iiif_presentation_order
    self.items_from_solr.order(SolrFields::PAGE_NUMBER,
                               SolrFields::SUBPAGE_NUMBER,
                               SolrFields::TITLE).limit(9999)
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def key_item
    self.items.where(variant: Variants::KEY).limit(1).first
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
      # Get all of the elements with the same name as the source element...
      source_elements = self.elements.select{ |e| e.name == source_name }
      # Clone them into elements with the destination name...
      source_elements.each do |src_e|
        self.elements.build(name: dest_name,
                            value: src_e.value,
                            vocabulary: src_e.vocabulary)
        src_e.destroy!
      end
      self.save!
    end
  end

  ##
  # @return [Item, nil] The next item in a compound object, relative to the
  #                     instance, or nil if none or not applicable.
  # @see previous()
  #
  def next
    next_item = nil
    if self.parent and self.page_number
      next_item = Item.where(parent_repository_id: self.parent.repository_id,
                page_number: self.page_number + 1).limit(1).first
    end
    next_item
  end

  ##
  # Queries the database to obtain a Relation of all children that have a
  # variant of Variant::PAGE.
  #
  # @return [Relation]
  # @see pages_from_solr()
  #
  def pages
    self.items.where(variant: Variants::PAGE).
        order(:page_number, :subpage_number)
  end

  ##
  # Queries Solr to obtain a Relation of all children that have a
  # variant of Variant::PAGE.
  #
  # @return [Relation]
  # @see pages()
  #
  def pages_from_solr
    Item.solr.where(Item::SolrFields::PARENT_ITEM => self.repository_id).
        where(Item::SolrFields::VARIANT => Item::Variants::PAGE)
  end

  ##
  # @return [Item, nil]
  # @see all_parents()
  # @see root_parent()
  #
  def parent
    @parent = Item.find_by_repository_id(self.parent_repository_id) unless @parent
    @parent
  end

  ##
  # @return [Item, nil] The previous item in a compound object, relative to the
  #                     instance, or nil if none or not applicable.
  # @see next()
  #
  def previous
    prev_item = nil
    if self.parent and self.page_number
      prev_item = Item.where(parent_repository_id: self.parent.repository_id,
                             page_number: self.page_number - 1).limit(1).first
    end
    prev_item
  end

  ##
  # Infers the primary media category of the instance by analyzing its
  # binaries' media categories.
  #
  # @return [Integer, nil] One of the Binary::MediaCategory constant values.
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
  # Propagates roles from the instance to all of its descendents. This is an
  # O(n) operation.
  #
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def propagate_roles(task = nil)
    ActiveRecord::Base.transaction do
      # Save callbacks will call this method on direct children, so there is
      # no need to crawl deeper levels of the child subtree.
      num_items = self.items.count
      self.items.each_with_index do |item, index|
        item.save!

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
      end
    end
  end

  def purge_cached_images
    ImageServer.instance.purge_item_from_cache(self)
  end

  ##
  # @return [Item, nil] The instance's assigned representative item, which may
  #                     be nil. For the purposes of getting "the"
  #                     representative item, `effective_representative_item`
  #                     should be used instead.
  # @see effective_representative_item
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
  # @return [Item, nil]
  # @see parent()
  # @see all_parents()
  #
  def root_parent
    p = self.parent
    while p
      break unless p.parent
      p = p.parent
    end
    p
  end

  ##
  # @return [Hash]
  #
  def solr_document
    Solr.instance.get('select', params: {
        q: "#{Item::SolrFields::ID}:#{self.repository_id}" })
  end

  ##
  # @return [String] The repository ID.
  #
  def solr_id
    self.repository_id
  end

  ##
  # @return [Item]
  #
  def supplementary_item
    self.items.where(variant: Variants::SUPPLEMENT).limit(1).first
  end

  ##
  # @return [Item] The item's table-of-contents item, if available.
  #
  def table_of_contents_item
    self.items.where(variant: Variants::TABLE_OF_CONTENTS).limit(1).first
  end

  ##
  # @return [Element]
  #
  def title
    t = self.element(:title)&.value
    t.present? ? t : self.repository_id
  end

  ##
  # @return [Item] The item's title item, if available.
  #
  def title_item
    self.items.where(variant: Variants::TITLE).limit(1).first
  end

  def to_param
    self.repository_id
  end

  def to_s
    self.title
  end

  ##
  # @return [Hash]
  #
  def to_solr
    doc = {}
    doc[SolrFields::ID] = self.solr_id
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::COLLECTION] = self.collection_repository_id
    doc[SolrFields::COLLECTION_PUBLISHED] = (self.collection.published and
        self.collection.published_in_dls)
    doc[SolrFields::DATE] = self.date.utc.iso8601 if self.date
    doc[SolrFields::EFFECTIVE_ALLOWED_ROLES] =
        self.effective_allowed_roles.map(&:key)
    doc[SolrFields::EFFECTIVE_DENIED_ROLES] =
        self.effective_denied_roles.map(&:key)
    doc[SolrFields::FULL_TEXT] = self.full_text

    if [Variants::FILE, Variants::DIRECTORY].include?(self.variant)
      # (parent title)-(parent title)-(parent title)-(title)
      doc[SolrFields::GROUPED_SORT] =
          (all_parents.map(&:title).reverse + [self.title]).join('-')
    else
      # parents: (repository ID)-(variant)-(page)-(subpage)-(title)
      # children: (parent ID)-(variant)-(page)-(subpage)-(title)
      sort_first_token = '000000'
      sort_last_token = 'ZZZZZZ'
      doc[SolrFields::GROUPED_SORT] =
          "#{self.parent_repository_id.present? ? self.parent_repository_id : self.repository_id}-"\
          "#{self.variant.present? ? self.variant : sort_first_token}-"\
          "#{self.page_number.present? ? self.page_number : sort_last_token}-"\
          "#{self.subpage_number.present? ? self.subpage_number : sort_last_token}-"\
          "#{self.title.present? ? self.title : sort_last_token}"
    end
    doc[SolrFields::LAST_INDEXED] = Time.now.utc.iso8601
    if self.latitude and self.longitude
      doc[SolrFields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    doc[SolrFields::PAGE_NUMBER] = self.page_number
    doc[SolrFields::PARENT_ITEM] = self.parent_repository_id
    doc[SolrFields::PRIMARY_MEDIA_CATEGORY] = self.primary_media_category
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::REPRESENTATIVE_ITEM_ID] = self.representative_item_repository_id
    doc[SolrFields::SUBPAGE_NUMBER] = self.subpage_number
    doc[SolrFields::TITLE] = self.title
    doc[SolrFields::TOTAL_BYTE_SIZE] = self.binaries.map{ |b| b.byte_size }.
        select{ |s| s }.sum
    doc[SolrFields::VARIANT] = self.variant

    self.elements.each do |element|
      doc[element.solr_multi_valued_field] ||= []
      doc[element.solr_multi_valued_field] << element.value
      doc[element.solr_single_valued_field] = element.value
    end

    doc
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
    return unless self.binaries.count > 0

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
  # This method must be kept in sync with as_json().
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
      self.date = TimeUtil.string_date_to_time(struct['date'])
      self.embed_tag = struct['embed_tag']
      self.full_text = struct['full_text']
      # id is not modifiable
      self.latitude = struct['latitude']
      self.longitude = struct['longitude']
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

      # date (normalized)
      self.date = TimeUtil.string_date_to_time(row['normalizedDate'])

      # latitude
      self.latitude = row['latitude'].strip.to_f if row['latitude']

      # longitude
      self.longitude = row['longitude'].strip.to_f if row['longitude']

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

  private

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
    bs = self.binaries.select{ |b| b.binary_type == Binary::Type::PRESERVATION_MASTER and
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
        "#{bs.human_readable_type} (#{bs.absolute_local_pathname})")

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
  # Tries to set the normalized latitude/longitude from a metadata element, if
  # the former are empty.
  #
  def set_normalized_coords
    if self.latitude.blank? and self.longitude.blank?
      coords_elem = self.elements.select{ |e| e.name == 'coordinates' }.first
      if coords_elem
        coords = SpaceUtil.string_coordinates_to_coordinates(coords_elem.value)
        if coords
          self.latitude = coords[:latitude]
          self.longitude = coords[:longitude]
        end
      end
    end
  end

  ##
  # Tries to set the normalized date from a date element, if the former is
  # empty.
  #
  def set_normalized_date
    if self.date.blank?
      date_elem = self.elements.select{ |e| e.name == 'date' }.first ||
          self.elements.select{ |e| e.name == 'dateCreated' }.first
      if date_elem
        self.date = TimeUtil.string_date_to_time(date_elem.value)
      end
    end
  end

end
