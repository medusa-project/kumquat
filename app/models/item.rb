class Item < Entity

  class SolrFields
    ACCESS_MASTER_HEIGHT = 'access_master_height_ii'
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
    ACCESS_MASTER_URL = 'access_master_url_si'
    ACCESS_MASTER_WIDTH = 'access_master_width_ii'
    BIB_ID = 'bib_id_si'
    COLLECTION = 'collection_si'
    CREATED = 'created_dti'
    DATE = 'date_dti'
    FULL_TEXT = 'full_text_txti'
    LAST_MODIFIED = 'last_modified_dti'
    LAT_LONG = 'lat_long_loc'
    METADATA_PATHNAME = 'metadata_pathname_si'
    PAGE_NUMBER = 'page_number_ii'
    PARENT_ITEM = 'parent_si'
    PRESERVATION_MASTER_HEIGHT = 'preservation_master_height_ii'
    PRESERVATION_MASTER_MEDIA_TYPE = 'preservation_master_media_type_si'
    PRESERVATION_MASTER_PATHNAME = 'preservation_master_pathname_si'
    PRESERVATION_MASTER_URL = 'preservation_master_url_si'
    PRESERVATION_MASTER_WIDTH = 'preservation_master_width_ii'
    PUBLISHED = 'published_bi'
    REPRESENTATIVE_ITEM_ID = 'representative_item_id_si'
    SEARCH_ALL = 'searchall_txtim'
    SUBCLASS = 'subclass_si'
    SUBPAGE_NUMBER = 'subpage_number_ii'
  end

  # These need to be kept in sync with the values in object.xsd.
  class Subclasses
    DIRECTORY = 'Directory'
    FILE = 'File'
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    KEY = 'Key'
    PAGE = 'Page'
    TITLE = 'Title'
  end

  # @!attribute bib_id
  #   @return [String]
  attr_accessor :bib_id

  # @!attribute bytestreams
  #   @return [Set<Bytestream>]
  attr_accessor :bytestreams

  # @!attribute collection_id
  #   @return [String]
  attr_accessor :collection_id

  # @!attribute created
  #   @return [Time]
  attr_accessor :created

  # @!attribute date
  #   @return [Time]
  attr_accessor :date

  # @!attribute full_text
  #   @return [String]
  attr_accessor :full_text

  # @!attribute last_modified
  #   @return [Time]
  attr_accessor :last_modified

  # @!attribute latitude
  #   @return [Float]
  attr_accessor :latitude

  # @!attribute longitude
  #   @return [Float]
  attr_accessor :longitude

  # @!attribute metadata
  #   @return [Array]
  attr_reader :metadata

  # @!attribute metadata_pathname
  #   @return [String]
  attr_accessor :metadata_pathname

  # @!attribute page_number
  #   @return [Integer]
  attr_accessor :page_number

  # @!attribute parent_id
  #   @return [String]
  attr_accessor :parent_id

  # @!attribute published
  #   @return [Boolean]
  attr_accessor :published

  # @!attribute representative_item_id
  #   @return [String]
  attr_accessor :representative_item_id

  # @!attribute subclass One of the Item::Subclasses constants
  #   @return [String]
  attr_accessor :subclass

  # @!attribute subpage_number
  #   @return [Integer]
  attr_accessor :subpage_number

  ##
  # @param doc [Nokogiri::XML::Document]
  # @return [Item]
  #
  def self.from_solr(doc)
    item = Item.new
    item.id = doc[Entity::SolrFields::ID]
    item.bib_id = doc[SolrFields::BIB_ID]
    item.collection_id = doc[SolrFields::COLLECTION]
    if doc[SolrFields::CREATED]
      item.created = Time.parse(doc[SolrFields::CREATED])
    end
    if doc[SolrFields::DATE]
      item.date = Time.parse(doc[SolrFields::DATE])
    end
    if doc[Entity::SolrFields::LAST_INDEXED]
      item.last_indexed = Time.parse(doc[Entity::SolrFields::LAST_INDEXED])
    end
    if doc[SolrFields::LAST_MODIFIED]
      item.last_modified = Time.parse(doc[SolrFields::LAST_MODIFIED])
    end
    if doc[SolrFields::LAT_LONG]
      parts = doc[SolrFields::LAT_LONG].split(',')
      if parts.length == 2
        item.latitude = parts.first.to_f
        item.longitude = parts.last.to_f
      end
    end
    item.metadata_pathname = doc[SolrFields::METADATA_PATHNAME]
    item.page_number = doc[SolrFields::PAGE_NUMBER]
    item.parent_id = doc[SolrFields::PARENT_ITEM]
    item.representative_item_id = doc[SolrFields::REPRESENTATIVE_ITEM_ID]
    if doc[SolrFields::ACCESS_MASTER_PATHNAME] or
        doc[SolrFields::ACCESS_MASTER_URL]
      bs = Bytestream.new(item.collection.medusa_data_file_group)
      bs.height = doc[SolrFields::ACCESS_MASTER_HEIGHT]
      bs.media_type = doc[SolrFields::ACCESS_MASTER_MEDIA_TYPE]
      bs.file_group_relative_pathname = doc[SolrFields::ACCESS_MASTER_PATHNAME]
      bs.type = Bytestream::Type::ACCESS_MASTER
      bs.url = doc[SolrFields::ACCESS_MASTER_URL]
      bs.width = doc[SolrFields::ACCESS_MASTER_WIDTH]
      item.bytestreams << bs
    end
    item.full_text = doc[SolrFields::FULL_TEXT]
    if doc[SolrFields::PRESERVATION_MASTER_PATHNAME] or
        doc[SolrFields::PRESERVATION_MASTER_URL]
      bs = Bytestream.new(item.collection.medusa_data_file_group)
      bs.height = doc[SolrFields::PRESERVATION_MASTER_HEIGHT]
      bs.media_type = doc[SolrFields::PRESERVATION_MASTER_MEDIA_TYPE]
      bs.file_group_relative_pathname = doc[SolrFields::PRESERVATION_MASTER_PATHNAME]
      bs.type = Bytestream::Type::PRESERVATION_MASTER
      bs.url = doc[SolrFields::PRESERVATION_MASTER_URL]
      bs.width = doc[SolrFields::PRESERVATION_MASTER_WIDTH]
      item.bytestreams << bs
    end
    item.subclass = doc[SolrFields::SUBCLASS]
    item.subpage_number = doc[SolrFields::SUBPAGE_NUMBER]

    # descriptive metadata
    doc.keys.select{ |k| k.start_with?(Element.solr_prefix) and
        k.end_with?(Element.solr_suffix) }.each do |key|
      doc[key].each do |value|
        e = Element.named(key.gsub(Element.solr_prefix, '').chomp(Element.solr_suffix))
        e.value = value
        item.metadata << e
      end
    end

    item.published = doc[SolrFields::PUBLISHED]
    item.instance_variable_set('@persisted', true)
    item
  end

  def initialize
    super
    @bytestreams = Set.new
    @metadata = []
  end

  def access_master_bytestream
    self.bytestreams.select{ |bs| bs.type == Bytestream::Type::ACCESS_MASTER }.
        first
  end

  ##
  # @return [Relation] All of the instance's children.
  # @see items
  #
  def children
    unless @children
      @children = Item.where(SolrFields::PARENT_ITEM => self.id).
          order(SolrFields::PAGE_NUMBER)
    end
    @children
  end

  alias_method :items, :children

  ##
  # @return [Collection]
  #
  def collection
    unless @collection
      @collection = Collection.find_by_repository_id(self.collection_id)
    end
    @collection
  end

  def description
    elements = metadata.select{ |e| e.name == 'description' }
    elements.any? ? elements.first.value : nil
  end

  ##
  # @return [Boolean] True if any text was extracted; false if not
  #
  def extract_and_update_full_text
    bs = access_master_bytestream
    if bs and bs.exists?
      begin
        yomu = Yomu.new(bs.pathname)
        self.full_text = yomu.text.force_encoding('UTF-8')
      rescue Errno::EPIPE
        return false # nothing we can do
      else
        return self.full_text.present?
      end
    end
    false
  end

  ##
  # @return [Relation] All of the item's children that have a subclass of File
  #                    or Directory.
  # @see children
  # @see pages
  #
  def files
    unless @files
      file_classes = [Subclasses::FILE, Subclasses::DIRECTORY].join(' OR ')
      @files = Item.where(SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => "(#{file_classes})").
          order(SolrFields::PAGE_NUMBER)
    end
    @files
  end

  ##
  # @return [Item] The item's front matter item, if available.
  #
  def front_matter_item
    unless @front_matter_item
      @front_matter_item = Item.where(SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => Item::Subclasses::FRONT_MATTER).
          limit(1).first
    end
    @front_matter_item
  end

  ##
  # @return [Item] The item's index item, if available.
  #
  def index_item
    unless @index_item
      @index_item = Item.where(Item::SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => Item::Subclasses::INDEX).
          limit(1).first
    end
    @index_item
  end

  def is_audio?
    bs = self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
        self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
    bs and bs.is_audio?
  end

  def is_image?
    bs = self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
        self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
    bs and bs.is_image?
  end

  def is_pdf?
    bs = self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
        self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
    bs and bs.is_pdf?
  end

  def is_text?
    bs = self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
        self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
    bs and bs.is_text?
  end

  def is_video?
    bs = self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.first ||
        self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.first
    bs and bs.is_video?
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def key_item
    unless @key_item
      @key_item = Item.where(SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => Item::Subclasses::KEY).
          limit(1).first
    end
    @key_item
  end

  ##
  # @return [Relation]
  #
  def more_like_this
    Relation.new(self).more_like_this
  end

  ##
  # @return [Item, nil] The next item in a compound object, relative to the
  # instance, or nil if none or not applicable.
  # @see previous()
  #
  def next
    next_item = nil
    if self.parent_id and self.page_number
      next_item = Item.all.
          where(SolrFields::PARENT_ITEM => self.parent_id,
                SolrFields::PAGE_NUMBER => self.page_number + 1).
          limit(1).first
    end
    next_item
  end

  ##
  # @return [Relation] All of the item's children that have a subclass of Page.
  # @see children
  #
  def pages
    unless @pages
      @pages = Item.where(SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => Item::Subclasses::PAGE).
          order(SolrFields::PAGE_NUMBER)
    end
    @pages
  end

  ##
  # @return [Item]
  #
  def parent
    if self.parent_id
      @parent = Item.find(self.parent_id) unless @parent
    end
    @parent
  end

  def preservation_master_bytestream
    self.bytestreams.
        select{ |bs| bs.type == Bytestream::Type::PRESERVATION_MASTER }.first
  end

  ##
  # @return [Item, nil] The previous item in a compound object, relative to the
  # instance, or nil if none or not applicable.
  # @see next()
  #
  def previous
    prev_item = nil
    if self.parent_id and self.page_number
      prev_item = Item.all.
          where(SolrFields::PARENT_ITEM => self.parent_id,
                SolrFields::PAGE_NUMBER => self.page_number - 1).
          limit(1).first
    end
    prev_item
  end

  def representative_item
    # TODO: remove periods from representativeItemId in AIPs and get rid of the gsub()
    (self.representative_item_id ?
        Item.find_by_id(self.representative_item_id.gsub('.', '_')) : self) || self
  end

  def subtitle
    elements = metadata.select{ |e| e.name == 'alternativeTitle' }
    elements.any? ? elements.first.value : nil
  end

  def title
    elements = metadata.select{ |e| e.name == 'title' }
    elements.any? ? elements.first.value : nil
  end

  ##
  # @return [Item] The item's title item, if available.
  #
  def title_item
    unless @title_item
      @title_item = Item.where(SolrFields::PARENT_ITEM => self.id).
          where(SolrFields::SUBCLASS => Item::Subclasses::TITLE).
          limit(1).first
    end
    @title_item
  end

  ##
  # Overrides parent
  #
  # @return [Hash]
  #
  def to_solr
    doc = super
    doc[SolrFields::BIB_ID] = self.bib_id
    doc[SolrFields::CREATED] = self.created.utc.iso8601 + 'Z' if self.created
    doc[SolrFields::COLLECTION] = self.collection_id
    doc[SolrFields::PAGE_NUMBER] = self.page_number
    doc[SolrFields::PARENT_ITEM] = self.parent_id
    doc[SolrFields::DATE] = self.date.utc.iso8601 if self.date
    self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.each do |bs|
      doc[SolrFields::ACCESS_MASTER_HEIGHT] = bs.height
      doc[SolrFields::ACCESS_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::ACCESS_MASTER_PATHNAME] = bs.file_group_relative_pathname
      doc[SolrFields::ACCESS_MASTER_URL] = bs.url
      doc[SolrFields::ACCESS_MASTER_WIDTH] = bs.width
    end
    doc[SolrFields::FULL_TEXT] = self.full_text
    if self.last_modified
      doc[SolrFields::LAST_MODIFIED] = self.last_modified.utc.iso8601 + 'Z'
    end
    if self.latitude and self.longitude
      doc[SolrFields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    doc[SolrFields::METADATA_PATHNAME] = self.metadata_pathname
    self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.each do |bs|
      doc[SolrFields::PRESERVATION_MASTER_HEIGHT] = bs.height
      doc[SolrFields::PRESERVATION_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::PRESERVATION_MASTER_PATHNAME] = bs.file_group_relative_pathname
      doc[SolrFields::PRESERVATION_MASTER_URL] = bs.url
      doc[SolrFields::PRESERVATION_MASTER_WIDTH] = bs.width
    end
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::REPRESENTATIVE_ITEM_ID] = self.representative_item_id
    doc[SolrFields::SUBCLASS] = self.subclass
    doc[SolrFields::SUBPAGE_NUMBER] = self.subpage_number

    self.metadata.each do |element|
      doc[element.solr_multi_valued_field] ||= []
      doc[element.solr_multi_valued_field] << element.value
      doc[element.solr_single_valued_field] = element.value
    end

    doc
  end

end
