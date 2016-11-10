##
# Encapsulates a unit of intellectual content.
#
# All items reside in a collection. An item may have one or more child items,
# as may any of those, forming a tree. It may also have one or more
# Bytestreams, each corresponding to a file in Medusa.
#
# Items have a number of properties of their own as well as a one-to-many
# relationship with ItemElement, which encapsulates a metadata element. The set
# of elements that an item contains is typically shaped by its collection's
# metadata profile, although there is no constraint in place to keep an item
# from being associated with other elements.
#
# Note that Medusa is not item-aware; items are a DLS entity. Item IDs
# correspond to Medusa file/directory IDs depending on a collection's content
# profile. These IDs are stored in `repository_id`, NOT `id`.
#
# Items have a soft pointer to their collection and parent item based on
# repository ID, rather than a belongs_to/has_many on their database ID.
# This is to be able to establish structure outside of the application.
#
# Items are searchable via ActiveRecord as well as via Solr. Instances are
# automatically indexed in Solr (see `to_solr`) and the Solr search
# functionality is available via the `solr` class method.
#
class Item < ActiveRecord::Base

  include AuthorizableByRole
  include SolrQuerying

  class SolrFields
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
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
    ID = 'id'
    LAST_MODIFIED = 'last_modified_dti'
    LAT_LONG = 'lat_long_loc'
    LAST_INDEXED = 'last_indexed_dti'
    PAGE_NUMBER = 'page_number_ii'
    PARENT_ITEM = 'parent_item_si'
    PRESERVATION_MASTER_MEDIA_TYPE = 'preservation_master_media_type_si'
    PRESERVATION_MASTER_PATHNAME = 'preservation_master_pathname_si'
    PUBLISHED = 'published_bi'
    REPRESENTATIVE_ITEM_ID = 'representative_item_id_si'
    SEARCH_ALL = 'searchall_natsort_en_im'
    SUBPAGE_NUMBER = 'subpage_number_ii'
    TITLE = 'title_natsort_en_i'
    VARIANT = 'variant_si'
  end

  class Variants
    DIRECTORY = 'Directory'
    FILE = 'File'
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    KEY = 'Key'
    PAGE = 'Page'
    TABLE_OF_CONTENTS = 'TableOfContents'
    TITLE = 'Title'
  end

  NON_DESCRIPTIVE_TSV_COLUMNS = %w(uuid parentId preservationMasterPathname
    accessMasterPathname variant pageNumber subpageNumber latitude longitude
    contentdmAlias contentdmPointer)
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

  has_many :bytestreams, inverse_of: :item, dependent: :destroy
  has_many :elements, class_name: 'ItemElement', inverse_of: :item,
           dependent: :destroy

  validates_format_of :collection_repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid'
  validates_format_of :parent_repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true
  validates_format_of :repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid'
  validates_format_of :representative_item_repository_id,
                      with: UUID_REGEX,
                      message: 'UUID is invalid',
                      allow_blank: true

  before_save :prune_identical_elements, :set_effective_roles
  after_update :propagate_roles
  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

  ##
  # Returns a tab-separated list of applicable technical elements, plus one
  # column per element definition in the item's collection's metadata profile.
  #
  # Headings are guaranteed to be consistent with the output of to_tsv as long
  # as the passed-in MetadataProfile is the same as the one assigned to an
  # item's collection.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [String] Tab-separated values with trailing newline.
  # @see to_tsv
  #
  def self.tsv_header(metadata_profile)
    columns = NON_DESCRIPTIVE_TSV_COLUMNS
    metadata_profile.elements.each do |ed|
      # There will be one column per MetadataProfileElement vocabulary. Column
      # headings are in the format "vocabKey:elementName", except the
      # uncontrolled vocabulary which will not have a vocabKey prefix.
      columns += ed.vocabularies.sort{ |v| v.key <=> v.key }.map do |vocab|
        vocab.key != Vocabulary::UNCONTROLLED_KEY ?
            "#{vocab.key}:#{ed.name}" : ed.name
      end
    end
    columns.join("\t") + TSV_LINE_BREAK
  end

  ##
  # @return [String]
  #
  def self.xml_schema
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.schema('xmlns:xs': 'http://www.w3.org/2001/XMLSchema',
                 'xmlns:dls': 'http://digital.library.illinois.edu/terms#',
                 targetNamespace: 'http://digital.library.illinois.edu/terms#',
                 elementFormDefault: 'qualified',
                 attributeFormDefault: 'unqualified') do
        xml['xs'].complexType(name: 'Item') do
          xml['xs'].sequence do
            xml.comment('******************* TECHNICAL ELEMENTS *******************')

            xml.comment('DLS UUID of the item. REQUIRED.')
            xml['xs'].element(name: 'repositoryId', minOccurs: 1, maxOccurs: 1) do
              xml['xs'].simpleType do
                xml['xs'].restriction(base: 'xs:token') do
                  xml['xs'].pattern(value: UUID_REGEX)
                end
              end
            end

            xml.comment('Medusa UUID of the collection in which the item resides. REQUIRED.')
            xml['xs'].element(name: 'collectionId', minOccurs: 1, maxOccurs: 1) do
              xml['xs'].simpleType do
                xml['xs'].restriction(base: 'xs:token') do
                  xml['xs'].pattern(value: UUID_REGEX)
                end
              end
            end

            xml.comment('repositoryId of the item that best represents the entity, '\
            'for the purposes of e.g. rendering a thumbnail image. For example, for '\
            'a compound object, it could be the first page.')
            xml['xs'].element(name: 'representativeItemId', minOccurs: 0, maxOccurs: 1) do
              xml['xs'].simpleType do
                xml['xs'].restriction(base: 'xs:token') do
                  xml['xs'].pattern(value: UUID_REGEX)
                end
              end
            end

            xml.comment('Whether the item is publicly accessible. Will default to '\
            'true if not supplied.')
            xml['xs'].element(name: 'published', type: 'xs:boolean',
                              minOccurs: 0, maxOccurs: 1)

            xml['xs'].comment('"Full text" of the item, which will viewable and indexed '\
            'for searching.')
            xml['xs'].element(name: 'fullText', type: 'xs:string',
                              minOccurs: 0, maxOccurs: 1)

            xml['xs'].comment('Page number of an item with a variant of "Page," '\
            'starting at 1. Used for sorting and previous/next navigation.')
            xml['xs'].element(name: 'pageNumber', type: 'xs:positiveInteger',
                              minOccurs: 0, maxOccurs: 1)

            xml['xs'].comment('Subpage number of an item that is a fragment of a page, '\
            'starting at 1.')
            xml['xs'].element(name: 'subpageNumber', type: 'xs:positiveInteger',
                              minOccurs: 0, maxOccurs: 1)

            xml['xs'].comment('Spatial longitude in decimal degrees.')
            xml['xs'].element(name: 'longitude', type: 'xs:float',
                              minOccurs: 0, maxOccurs: 1)

            xml['xs'].comment('Spatial latitude in decimal degrees.')
            xml['xs'].element(name: 'latitude', type: 'xs:float',
                              minOccurs: 0, maxOccurs: 1)

            xml.comment('A way of refining the type of an item, which may affect '\
            'how it is displayed. (Generally, "compound object" pages require '\
            'a value of "Page".)')
            xml['xs'].element(name: 'variant', minOccurs: 0, maxOccurs: 1) do
              xml['xs'].simpleType do
                xml['xs'].restriction(base: 'xs:token') do
                  Item::Variants::constants.each do |const|
                    xml['xs'].enumeration(value: const.to_s.downcase.camelize)
                  end
                end
              end
            end

            xml.comment('CONTENTdm alias ("CISOROOT") of the item, if it '\
            'originated in CONTENTdm.')
            xml['xs'].element(name: 'contentdmAlias', type: 'xs:token',
                              minOccurs: 0, maxOccurs: 1)

            xml.comment('CONTENTdm pointer ("CISOPTR") of the item, if it '\
            'originated in CONTENTdm.')
            xml['xs'].element(name: 'contentdmPointer', type: 'xs:positiveInteger',
                              minOccurs: 0, maxOccurs: 1)

            xml.comment('Allowed role keys.')
            xml['xs'].element(name: 'allowedRoles', minOccurs: 0, maxOccurs: 1) do
              xml['xs'].complexType do
                xml['xs'].sequence do
                  xml['xs'].element(name: 'key', type: 'xs:token',
                                    minOccurs: 1, maxOccurs: 'unbounded')
                end
              end
            end

            xml.comment('Denied role keys.')
            xml['xs'].element(name: 'deniedRoles', minOccurs: 0, maxOccurs: 1) do
              xml['xs'].complexType do
                xml['xs'].sequence do
                  xml['xs'].element(name: 'key', type: 'xs:token',
                                    minOccurs: 1, maxOccurs: 'unbounded')
                end
              end
            end

            xml.comment('******************* DESCRIPTIVE ELEMENTS *******************')

            Element.all.order(:name).each do |e|
              xml['xs'].element(name: e.name, type: 'xs:normalizedString',
                                minOccurs: 0, maxOccurs: 'unbounded') do
                xml['xs'].complexType do
                  xml['xs'].attribute(name: 'vocabularyKey', type: 'xs:token', use: 'required')
                  xml['xs'].attribute(name: 'dataType', type: 'DataType', use: 'required')
                end
              end
            end
          end
        end

        xml['xs'].simpleType(name: 'DataType') do
          xml['xs'].restriction(base: 'xs:token') do
            xml['xs'].enumeration(value: 'string')
            xml['xs'].enumeration(value: 'URI')
          end
        end
      end
    end
    builder.to_xml
  end

  ##
  # @return [Bytestream]
  #
  def access_master_bytestream
    self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
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
  # @return [Element]
  #
  def description
    self.element(:description)&.value
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
  # Convenience method that retrieves one element with the given name from the
  # instance's `elements` relationship.
  #
  # @param name [String, Symbol] Element name
  # @return [ItemElement]
  #
  def element(name)
    self.elements.select{ |e| e.name == name.to_s }.first
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
  # @return [String,nil]
  #
  def iiif_identifier
    id = nil
    bs = self.access_master_bytestream
    if !bs or (!bs.is_image? and !bs.is_pdf?)
      bs = self.preservation_master_bytestream
      if !bs or (!bs.is_image? and !bs.is_pdf?)
        bs = nil
      end
    end
    if bs
      id = bs.repository_relative_pathname.reverse.chomp('/').reverse
    end
    id
  end

  ##
  # @return [String, nil] IIIF info.json URL, or nil if the instance is not an
  #                       image.
  #
  def iiif_info_url
    url = self.iiif_url
    url ? "#{url}/info.json" : nil
  end

  ##
  # @return [String,nil]
  #
  def iiif_url
    url = nil
    id = self.iiif_identifier
    if id
      url = Configuration.instance.iiif_url + '/' + CGI.escape(id)
    end
    url
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
  # @return [Boolean]
  #
  def is_audio?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs&.is_audio?
  end

  ##
  # @return [Boolean] Whether the instance has any children with a "page"
  #                   variant.
  #
  def is_compound?
    self.pages.count > 0
  end

  ##
  # @return [Boolean]
  #
  def is_image?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs&.is_image?
  end

  ##
  # @return [Boolean]
  #
  def is_pdf?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs&.is_pdf?
  end

  ##
  # @return [Boolean]
  #
  def is_text?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs&.is_text?
  end

  ##
  # @return [Boolean]
  #
  def is_video?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs&.is_video?
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
  # @see root_parent()
  #
  def parent
    @parent = Item.find_by_repository_id(self.parent_repository_id) unless @parent
    @parent
  end

  ##
  # @return [Bytestream, nil]
  #
  def preservation_master_bytestream
    self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
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
  # @return [Element]
  #
  def subtitle
    self.element(:alternativeTitle)&.value
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
  # @param schema_version [Integer] One of the versions in
  #                                 `ItemXmlIngester::SCHEMA_VERSIONS`
  #
  def to_dls_xml(schema_version)
    case schema_version.to_i
      when 3
        return to_dls_xml_v3
    end
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
    doc[SolrFields::LAST_INDEXED] = Time.now.utc.iso8601
    if self.latitude and self.longitude
      doc[SolrFields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    doc[SolrFields::PAGE_NUMBER] = self.page_number
    doc[SolrFields::PARENT_ITEM] = self.parent_repository_id
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::REPRESENTATIVE_ITEM_ID] = self.representative_item_repository_id
    doc[SolrFields::SUBPAGE_NUMBER] = self.subpage_number
    doc[SolrFields::TITLE] = self.title
    doc[SolrFields::VARIANT] = self.variant
    bs = self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    if bs
      doc[SolrFields::ACCESS_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::ACCESS_MASTER_PATHNAME] = bs.repository_relative_pathname
    end
    bs = self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    if bs
      doc[SolrFields::PRESERVATION_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::PRESERVATION_MASTER_PATHNAME] = bs.repository_relative_pathname
    end
    self.elements.each do |element|
      doc[element.solr_multi_valued_field] ||= []
      doc[element.solr_multi_valued_field] << element.value
      doc[element.solr_single_valued_field] = element.value
    end

    doc
  end

  ##
  # Transactionally updates an instance's metadata elements from the metadata
  # embedded within its preservation or access master bytestream.
  #
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :include_date_created
  # @raises [IOError]
  #
  def update_from_embedded_metadata(options = {})
    ActiveRecord::Base.transaction do
      self.elements.destroy_all
      self.elements += elements_from_embedded_metadata(options)
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
      date = row['date'] || row['dateCreated']
      if date
        self.date = TimeUtil.string_date_to_time(date.strip)
      end

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
      row.each do |heading, multi_value|
        # Skip columns with an empty value.
        next unless multi_value.present?

        # Vocabulary columns will have a heading of "vocabKey:elementName",
        # except uncontrolled columns which will have a heading of just
        # "elementName".
        heading_parts = heading.split(':')
        element_name = heading_parts.last

        # Skip non-descriptive columns.
        next if NON_DESCRIPTIVE_TSV_COLUMNS.include?(element_name)

        # To avoid data loss, we will accept any available descriptive element,
        # whether or not it is present in the collection's metadata profile.
        if ItemElement.all_descriptive.map(&:name).include?(element_name)
          multi_value.split(TSV_MULTI_VALUE_SEPARATOR).select(&:present?).each do |raw_value|
            e = ItemElement.named(element_name)
            # raw_value may be an arbitrary string; it may be a URI (enclosed
            # in angle brackets); or it may be both, joined with
            # TSV_URI_VALUE_SEPARATOR.
            value_parts = raw_value.split(TSV_URI_VALUE_SEPARATOR)
            value_parts.each do |part|
              if part.start_with?('<') and part.end_with?('>') and part.length > 2
                e.uri = part[1..part.length - 2]
              elsif part.present?
                e.value = part
              end
            end

            # Assign the correct vocabulary.
            if heading_parts.length > 1
              e.vocabulary = Vocabulary.find_by_key(heading_parts.first)
              # Disallow invalid vocabularies.
              unless e.vocabulary
                raise ArgumentError,
                      "Column contains an unrecognized vocabulary key: #{heading}"
              end
            else
              e.vocabulary = Vocabulary.uncontrolled
            end
            self.elements << e
          end
        else
          raise ArgumentError,
                "Column contains an unrecognized element name: #{element_name}"
        end
      end
      self.save!
    end
  end

  ##
  # Updates an instance from valid DLS XML.
  #
  # @param node [Nokogiri::XML::Node]
  # @param schema_version [Integer]
  # @return [Item]
  # @raises [ArgumentError]
  #
  def update_from_xml(node, schema_version)
    case schema_version
      when 3
        namespaces = ItemXmlIngester::XML_V3_NAMESPACES
        prefix = 'dls'
    end

    ActiveRecord::Base.transaction do
      # These need to be deleted first, otherwise it would be impossible for
      # an update to remove them.
      self.elements.destroy_all
      self.allowed_roles.clear
      self.denied_roles.clear

      # CONTENTdm alias
      alias_ = node.xpath("//#{prefix}:contentdmAlias", namespaces).first
      self.contentdm_alias = alias_.content.strip if alias_

      # CONTENTdm pointer
      ptr = node.xpath("//#{prefix}:contentdmPointer", namespaces).first
      self.contentdm_pointer = ptr.content.strip.to_i if ptr

      # date
      date = node.xpath("//#{prefix}:date", namespaces).first ||
          node.xpath("//#{prefix}:dateCreated", namespaces).first
      self.date = TimeUtil.string_date_to_time(date.content.strip) if date

      # full text
      ft = node.xpath("//#{prefix}:fullText", namespaces).first
      self.full_text = ft.content.strip if ft

      # latitude
      lat = node.xpath("//#{prefix}:latitude", namespaces).first
      self.latitude = lat.content.strip.to_f if lat

      # longitude
      long = node.xpath("//#{prefix}:longitude", namespaces).first
      self.longitude = long.content.strip.to_f if long

      # page number
      page = node.xpath("//#{prefix}:pageNumber", namespaces).first
      self.page_number = page.content.strip.to_i if page

      # published
      published = node.xpath("//#{prefix}:published", namespaces).first
      self.published = %w(true 1).include?(published.content.strip) if published

      # repository ID
      rep_id = node.xpath("//#{prefix}:repositoryId", namespaces).first
      self.repository_id = rep_id.content.strip if rep_id

      # representative item ID
      rep_item_id = node.xpath("//#{prefix}:representativeItemId", namespaces).first
      self.representative_item_repository_id = rep_item_id.content.strip if rep_item_id

      # roles (allowed)
      node.xpath("//#{prefix}:allowedRoles/key", namespaces).each do |key|
        role = Role.find_by_key(key.content)
        raise ArgumentError, "Role does not exist: #{key}" unless role
        self.allowed_roles << role
      end

      # roles (denied)
      node.xpath("//#{prefix}:deniedRoles/key", namespaces).each do |key|
        role = Role.find_by_key(key.content)
        raise ArgumentError, "Role does not exist: #{key}" unless role
        self.denied_roles << role
      end

      # subpage number
      page = node.xpath("//#{prefix}:subpageNumber", namespaces).first
      self.subpage_number = page.content.strip.to_i if page

      node.xpath("//#{prefix}:*", namespaces).
          select{ |node| ItemElement.all_descriptive.map(&:name).include?(node.name) }.
          each do |node|
        # Add a new element
        e = ItemElement.named(node.name)
        case node['dataType']
          when 'URI'
            e.uri = node.content.strip
          else
            e.value = node.content.strip
        end
        e.vocabulary = Vocabulary.find_by_key(node['vocabularyKey'])
        self.elements << e
      end

      # variant
      variant = node.xpath("//#{prefix}:variant", namespaces).first
      self.variant = variant.content.strip if variant

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
    elements = []
    if value.respond_to?(:each)
      value.select(&:present?).each do |val|
        elements << ItemElement.new(name: dest_elem, value: val,
                                    vocabulary: Vocabulary.uncontrolled)
      end
    elsif value.present?
      elements << ItemElement.new(name: dest_elem, value: value,
                                  vocabulary: Vocabulary.uncontrolled)
    end
    elements
  end

  ##
  # @param options [Hash<Symbol,Object>]
  # @option options [Boolean] :include_date_created
  # @return [Array<ItemElement>]
  #
  def elements_from_embedded_metadata(options = {})
    # Get the bytestream from which the metadata will be extracted
    bs = self.preservation_master_bytestream || self.access_master_bytestream
    unless bs
      Rails.logger.info('Item.elements_from_embedded_metadata(): no bytestreams')
      return
    end

    Rails.logger.debug("Item.elements_from_embedded_metadata: using "\
        "#{bs.human_readable_type} (#{bs.absolute_local_pathname})")

    # Get its embedded IIM metadata
    iim_metadata = bs.metadata.select{ |m| m[:category] == 'IPTC' }

    elements = []

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

      # Try to add a normalized date.
      date_elem = iim_metadata.select{ |e| e[:label] == 'Date Created' }.first
      self.date = TimeUtil.string_date_to_time(date_elem[:value]) if date_elem
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

  def to_dls_xml_v3
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['dls'].Object('xmlns:dls' => ItemXmlIngester::XML_V3_NAMESPACES['dls']) {
        xml['dls'].repositoryId {
          xml.text(self.repository_id)
        }
        xml['dls'].collectionId {
          xml.text(self.collection_repository_id)
        }
        if self.parent_repository_id.present?
          xml['dls'].parentId {
            xml.text(self.parent_repository_id)
          }
        end
        if self.representative_item_repository_id.present?
          xml['dls'].representativeItemId {
            xml.text(self.representative_item_repository_id)
          }
        end
        xml['dls'].published {
          xml.text(self.published ? 'true' : 'false')
        }
        if self.full_text.present?
          xml['dls'].fullText {
            xml.text(self.full_text)
          }
        end
        if self.page_number.present?
          xml['dls'].pageNumber {
            xml.text(self.page_number)
          }
        end
        if self.subpage_number.present?
          xml['dls'].subpageNumber {
            xml.text(self.subpage_number)
          }
        end
        if self.latitude.present?
          xml['dls'].latitude {
            xml.text(self.latitude)
          }
        end
        if self.longitude.present?
          xml['dls'].longitude {
            xml.text(self.longitude)
          }
        end
        if self.created_at.present?
          xml['dls'].created {
            xml.text(self.created_at.utc.iso8601)
          }
        end
        if self.updated_at.present?
          xml['dls'].lastModified {
            xml.text(self.updated_at.utc.iso8601)
          }
        end
        if self.variant.present?
          xml['dls'].variant {
            xml.text(self.variant)
          }
        end
        if self.contentdm_alias.present?
          xml['dls'].contentdmAlias {
            xml.text(self.contentdm_alias)
          }
        end
        if self.contentdm_pointer.present?
          xml['dls'].contentdmPointer {
            xml.text(self.contentdm_pointer)
          }
        end

        if self.allowed_roles.any?
          xml['dls'].allowedRoles {
            self.allowed_roles.map(&:key).each do |role|
              xml['dls'].key {
                xml.text(role)
              }
            end
          }
        end
        if self.denied_roles.any?
          xml['dls'].deniedRoles {
            self.denied_roles.map(&:key).each do |role|
              xml['dls'].key {
                xml.text(role)
              }
            end
          }
        end

        self.elements.order(:name).each do |element|
          vocab_key = element.vocabulary ?
              element.vocabulary.key : Vocabulary::uncontrolled.key

          if element.value.present?
            xml['dls'].send(element.name,
                            vocabularyKey: vocab_key,
                            dataType: 'string') {
              xml.text(element.value)
            }
          elsif element.uri.present?
            xml['dls'].send(element.name,
                            vocabularyKey: vocab_key,
                            dataType: 'URI') {
              xml.text(element.uri)
            }
          end
        end
      }
    end
    builder.to_xml
  end

end
