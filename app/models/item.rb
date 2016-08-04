##
# Encapsulates a unit of intellectual content.
#
# All items reside in a collection. An item may have one or more child items,
# as may any of those, forming a tree. It may also have one or more
# Bytestreams, each corresponding to a file in Medusa.
#
# Items have a number of properties of their own as well as a one-to-many
# relationship with Element, which encapsulates a metadata element. The set of
# elements that an item contains is typically shaped by its collection's
# metadata profile, although there is no constraint in place to keep an item
# from being associated with other elements.
#
# Note that Medusa is not item-aware; items are a DLS entity. Item IDs
# correspond to Medusa file/directory IDs depending on a collection's content
# profile. These IDs are stored in `repository_id`, NOT `id`, which is
# database-specific.
#
# Items have a soft pointer to their collection and parent item based on
# repository ID, rather than a belongs_to/has_many on their database ID.
# This is to be able to establish structure more easily outside of the
# application.
#
# Being an ActiveRecord entity, items are searchable via ActiveRecord as well
# as via Solr. Instances are automatically indexed in Solr (see `to_solr`) and
# the Solr search functionality is available via the `solr` class method.
#
class Item < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
    CLASS = 'class_si'
    COLLECTION = 'collection_si'
    CREATED = 'created_dti'
    DATE = 'date_dti'
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
    SEARCH_ALL = 'searchall_txtim'
    SUBPAGE_NUMBER = 'subpage_number_ii'
    TITLE = 'title_natsort_en_i'
    VARIANT = 'variant_si'
  end

  # These need to be kept in sync with the values in object.xsd.
  class Variants
    DIRECTORY = 'Directory'
    FILE = 'File'
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    KEY = 'Key'
    PAGE = 'Page'
    TITLE = 'Title'
  end

  MULTI_VALUE_SEPARATOR = '||'
  TSV_LINE_BREAK = "\n"
  UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

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

  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

  ##
  # Creates a new instance from valid DLS XML, persists it, and returns it.
  #
  # @param [Nokogiri::XML::Node] node
  # @return [Item]
  #
  def self.from_dls_xml(node, schema_version)
    item = Item.new
    item.update_from_xml(node, schema_version)
    item
  end

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
    # Must remain synchronized with the output of to_tsv.
    elements = %w(uuid parentId preservationMasterPathname accessMasterPathname
                  variant pageNumber subpageNumber latitude longitude)
    metadata_profile.element_defs.each do |ed|
      # There will be one column per ElementDef vocabulary. Column headings are
      # in the format "vocabKey:elementName", except the uncontrolled vocabulary
      # which will not get a vocabKey prefix.
      elements += ed.vocabularies.sort{ |v| v.key <=> v.key }.map do |vocab|
        vocab.key != Vocabulary::UNCONTROLLED_KEY ?
            "#{vocab.key}:#{ed.name}" : ed.name
      end
    end
    elements.join("\t") + TSV_LINE_BREAK
  end

  ##
  # Creates a new instance from valid DLS XML, persists it, and returns it.
  #
  # @param tsv [String] TSV
  # @param row [Hash<String,String>] TSV row
  # @param collection [Collection]
  # @return [Item]
  #
  def self.from_tsv(tsv, row, collection)
    item = Item.new
    item.collection = collection
    item.update_from_tsv(tsv, row)
    item
  end

  ##
  # @return [Bytestream]
  #
  def access_master_bytestream
    self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
  end

  def bib_id
    self.elements.select{ |e| e.name == 'bibId' }.first&.value
  end

  ##
  # @return [Collection]
  #
  def collection
    Collection.find_by_repository_id(self.collection_repository_id)
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
    self.elements.select{ |e| e.name == 'description' }.first&.value
  end

  def delete_from_solr
    Solr.instance.delete(self.solr_id)
  end

  ##
  # Returns the instance's effective representative item based on the following
  # order of preference:
  #
  # 1) The instance's assigned representative item (if it has one)
  # 2) The instance's first page (if it has any)
  # 3) The instance's first child item (if it has any)
  # 4) The instance itself
  #
  # @return [Item]
  # @see representative_item
  #
  def effective_representative_item
    self.representative_item || self.pages.first || self.items.first || self
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

  def index_in_solr
    Solr.instance.add(self.to_solr)
    # To improve the performance of imports, we will avoid saving here, as
    # this will be called in a before_save callback 99.99% of the time.
  end

  ##
  # @return [Item] The item's index item, if available.
  #
  def index_item
    self.items.where(variant: Variants::INDEX).limit(1).first
  end

  def is_audio?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs and bs.is_audio?
  end

  def is_image?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs and bs.is_image?
  end

  def is_pdf?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs and bs.is_pdf?
  end

  def is_text?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs and bs.is_text?
  end

  def is_video?
    bs = self.access_master_bytestream || self.preservation_master_bytestream
    bs and bs.is_video?
  end

  def items
    Item.where(parent_repository_id: self.repository_id)
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def key_item
    self.items.where(variant: Variants::KEY).limit(1).first
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
  #
  def parent
    Item.find_by_repository_id(self.parent_repository_id)
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
  # @return [String] The repository ID.
  #
  def solr_id
    self.repository_id
  end

  ##
  # @return [Element]
  #
  def subtitle
    self.elements.select{ |e| e.name == 'alternativeTitle' }.first&.value
  end

  ##
  # @return [Element]
  #
  def title
    t = self.elements.select{ |e| e.name == 'title' }.first&.value
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
    doc[SolrFields::DATE] = self.date.utc.iso8601 if self.date
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
  # @return [String] Tab-separated values with trailing newline.
  # @see tsv_header
  #
  def to_tsv
    # Columns must remain synchronized with the output of tsv_header. There
    # must be a fixed number of columns in a fixed order, in order to be able
    # to dump multiple items into the same document.
    # Properties with multiple values are placed in the same cell, separated
    # by MULTI_VALUE_SEPARATOR.
    columns = []
    columns << self.repository_id
    columns << self.parent_repository_id
    columns << self.preservation_master_bytestream&.repository_relative_pathname
    columns << self.access_master_bytestream&.repository_relative_pathname
    columns << self.variant
    columns << self.page_number
    columns << self.subpage_number
    columns << self.latitude
    columns << self.longitude

    self.collection.metadata_profile.element_defs.each do |pe|
      # An ElementDef will have one column per vocabulary.
      pe.vocabularies.order(:key).each do |vocab|
        columns << self.elements.
            select{ |e| e.name == pe.name and (e.vocabulary == vocab or (!e.vocabulary and vocab == Vocabulary.uncontrolled)) }.
            map(&:value).
            join(MULTI_VALUE_SEPARATOR)
      end
    end
    columns.join("\t") + TSV_LINE_BREAK
  end

  ##
  # Updates an instance's metadata elements from the metadata embedded within
  # its preservation master bytestream.
  #
  def update_from_embedded_metadata
    # Get the bytestream from which the metadata will be pulled
    bs = self.preservation_master_bytestream || self.access_master_bytestream
    return unless bs

    # Get its embedded metadata
    metadata = bs.metadata

    def copy_metadata(src_label, dest_elem, metadata)
      src_elem = metadata.select{ |e| e[:label] == src_label }.first
      if src_elem
        if src_elem[:value].respond_to?(:each)
          src_elem[:value].select{ |v| v.present? }.each do |value|
            self.elements.build(name: dest_elem, value: value,
                                vocabulary: Vocabulary.uncontrolled)
          end
        elsif src_elem[:value].present?
          self.elements.build(name: dest_elem, value: src_elem[:value],
                              vocabulary: Vocabulary.uncontrolled)
        end
      end
    end

    # This is a very abbreviated list of IPTC IIM fields that can easily map
    # to common ElementDefs. We do not check if these elements actually exist
    # in the item's metadata profile, but most profiles should include them,
    # and if not, no big deal.
    #
    # Obviously, this is very crude and a change in the effort/reward ratio
    # might warrant maintaining a master list of IIM fields and enabling
    # customizable mappings.
    copy_metadata('Author', 'creator', metadata)
    copy_metadata('Credit', 'creator', metadata)
    copy_metadata('Creator', 'creator', metadata)
    copy_metadata('Date Created', 'dateCreated', metadata)
    copy_metadata('Description', 'description', metadata)
    copy_metadata('Caption', 'description', metadata)
    copy_metadata('Copyright', 'rights', metadata)
    copy_metadata('Copyright Notice', 'rights', metadata)
    copy_metadata('Keywords', 'subject', metadata)
    copy_metadata('Headline', 'title', metadata)
    copy_metadata('Title', 'title', metadata)

    # If a date is present, try to add a normalized date element.
    date_elem = metadata.select{ |e| e[:label] == 'Date Created' }.first
    if date_elem
      date = TimeUtil.string_date_to_time(date_elem[:value])
      if date
        self.elements.build(name: 'date', value: date.utc.iso8601,
                            vocabulary: Vocabulary.uncontrolled)
      end
    end

    self.save! if save
  end

  ##
  # Updates an instance from a hash representing a TSV row.
  #
  # @param tsv [Array<Hash<String,String>>]
  # @param row [Hash<String,String>] Item serialized as a TSV row
  # @return [Item]
  # @raises [RuntimeError]
  #
  def update_from_tsv(tsv, row)
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

      # Metadata elements.
      row.each do |heading, value|
        # Skip columns with an empty value.
        next unless value.present?
        # Vocabulary columns will have a heading of "vocabKey:elementName",
        # except uncontrolled columns which will have a heading of just
        # "elementName".
        parts = heading.split(':')
        element_name = parts.last
        # To be safe, we will accept any descriptive element, whether or not it
        # is present in the collection's metadata profile.
        if ElementDef.all_descriptive.map(&:name).include?(element_name)
          value.split(MULTI_VALUE_SEPARATOR).select(&:present?).each do |value|
            e = ItemElement.named(element_name)
            e.value = value
            if parts.length > 1
              e.vocabulary = Vocabulary.find_by_key(parts.first)
              # Disallow invalid vocabularies.
              unless e.vocabulary
                raise "Column contains an invalid vocabulary: #{heading}"
              end
            else
              e.vocabulary = Vocabulary.uncontrolled
            end
            self.elements << e
          end
        end
      end

      # If the only changes were to dependent entities, this would not get
      # updated.
      self.updated_at = Time.now
      self.save!
    end
  end

  ##
  # Updates an instance from valid DLS XML.
  #
  # @param node [Nokogiri::XML::Node]
  # @param schema_version [Integer]
  # @return [Item]
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
      self.bytestreams.destroy_all
      self.elements.destroy_all

      # collection
      col_id = node.xpath("//#{prefix}:collectionId", namespaces).first
      self.collection_repository_id = col_id.content.strip if col_id

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

      # parent item
      parent = node.xpath("//#{prefix}:parentId", namespaces).first
      self.parent_repository_id = parent.content.strip if parent

      # published
      published = node.xpath("//#{prefix}:published", namespaces).first
      self.published = %w(true 1).include?(published.content.strip) if published

      # repository ID
      rep_id = node.xpath("//#{prefix}:repositoryId", namespaces).first
      self.repository_id = rep_id.content.strip if rep_id

      # representative item ID
      rep_item_id = node.xpath("//#{prefix}:representativeItemId", namespaces).first
      self.representative_item_repository_id = rep_item_id.content.strip if rep_item_id

      if schema_version == 1
        # subclass
        subclass = node.xpath("//#{prefix}:subclass", namespaces).first
        self.variant = subclass.content.strip if subclass
      else
        # variant
        variant = node.xpath("//#{prefix}:variant", namespaces).first
        self.variant = variant.content.strip if variant
      end

      # subpage number
      page = node.xpath("//#{prefix}:subpageNumber", namespaces).first
      self.subpage_number = page.content.strip.to_i if page

      node.xpath("//#{prefix}:*", namespaces).
          select{ |node| ItemElement.all_descriptive.map(&:name).include?(node.name) }.
          each do |node|
        # Add a new element
        e = ItemElement.named(node.name)
        e.value = node.content.strip
        self.elements << e
      end

      self.save!
    end
  end

  private

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

        self.elements.order(:name).each do |element|
          if element.value.present?
            xml['dls'].send(element.name) {
              xml.text(element.value)
            }
          end
        end
      }
    end
    builder.to_xml
  end

end
