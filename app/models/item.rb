class Item < Entity

  class Subclasses
    FRONT_MATTER = 'FrontMatter'
    INDEX = 'Index'
    KEY = 'Key'
    PAGE = 'Page'
    TITLE = 'Title'
  end

  # @!attribute bytestreams
  #   @return [Set<Bytestream>]
  attr_accessor :bytestreams

  # @!attribute collection_id
  #   @return [String]
  attr_accessor :collection_id

  # @!attribute date
  #   @return [Time]
  attr_accessor :date

  # @!attribute full_text
  #   @return [String]
  attr_accessor :full_text

  # @!attribute latitude
  #   @return [Float]
  attr_accessor :latitude

  # @!attribute longitude
  #   @return [Float]
  attr_accessor :longitude

  # @!attribute page_number
  #   @return [Integer]
  attr_accessor :page_number

  # @!attribute parent_id
  #   @return [String]
  attr_accessor :parent_id

  # @!attribute subpage_number
  #   @return [Integer]
  attr_accessor :subpage_number

  ##
  # @param doc [Nokogiri::XML::Document]
  # @return [Item]
  #
  def self.from_solr(doc)
    item = Item.new
    item.id = doc[Solr::Fields::ID]
    item.bib_id = doc[Solr::Fields::BIB_ID]
    item.collection_id = doc[Solr::Fields::COLLECTION]
    if doc[Solr::Fields::CREATED]
      item.created = Time.parse(doc[Solr::Fields::CREATED])
    end
    item.date = Time.parse(doc[Solr::Fields::DATE])
    if doc[Solr::Fields::LAST_INDEXED]
      item.last_indexed = Time.parse(doc[Solr::Fields::LAST_INDEXED])
    end
    if doc[Solr::Fields::LAST_MODIFIED]
      item.last_modified = Time.parse(doc[Solr::Fields::LAST_MODIFIED])
    end
    if doc[Solr::Fields::LAT_LONG]
      parts = doc[Solr::Fields::LAT_LONG].split(',')
      if parts.length == 2
        item.latitude = parts.first.to_f
        item.longitude = parts.last.to_f
      end
    end
    item.metadata_pathname = doc[Solr::Fields::METADATA_PATHNAME]
    item.page_number = doc[Solr::Fields::PAGE_NUMBER]
    item.parent_id = doc[Solr::Fields::PARENT_ITEM]
    item.representative_item_id = doc[Solr::Fields::REPRESENTATIVE_ITEM_ID]
    if doc[Solr::Fields::ACCESS_MASTER_PATHNAME] or
        doc[Solr::Fields::ACCESS_MASTER_URL]
      bs = Bytestream.new
      bs.height = doc[Solr::Fields::ACCESS_MASTER_HEIGHT]
      bs.media_type = doc[Solr::Fields::ACCESS_MASTER_MEDIA_TYPE]
      bs.repository_relative_pathname = doc[Solr::Fields::ACCESS_MASTER_PATHNAME]
      bs.type = Bytestream::Type::ACCESS_MASTER
      bs.url = doc[Solr::Fields::ACCESS_MASTER_URL]
      bs.width = doc[Solr::Fields::ACCESS_MASTER_WIDTH]
      item.bytestreams << bs
    end
    item.full_text = doc[Solr::Fields::FULL_TEXT]
    if doc[Solr::Fields::PRESERVATION_MASTER_PATHNAME] or
        doc[Solr::Fields::PRESERVATION_MASTER_URL]
      bs = Bytestream.new
      bs.height = doc[Solr::Fields::PRESERVATION_MASTER_HEIGHT]
      bs.media_type = doc[Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE]
      bs.repository_relative_pathname = doc[Solr::Fields::PRESERVATION_MASTER_PATHNAME]
      bs.type = Bytestream::Type::PRESERVATION_MASTER
      bs.url = doc[Solr::Fields::PRESERVATION_MASTER_URL]
      bs.width = doc[Solr::Fields::PRESERVATION_MASTER_WIDTH]
      item.bytestreams << bs
    end
    item.subclass = doc[Solr::Fields::SUBCLASS]
    item.subpage_number = doc[Solr::Fields::SUBPAGE_NUMBER]

    # descriptive metadata
    doc.keys.select{ |k| k.start_with?(Element.solr_prefix) and
        k.end_with?(Element.solr_suffix) }.each do |key|
      doc[key].each do |value|
        e = Element.named(key.gsub(Element.solr_prefix, '').chomp(Element.solr_suffix))
        e.value = value
        item.metadata << e
      end
    end

    item.published = doc[Solr::Fields::PUBLISHED]
    item.web_id = doc[Solr::Fields::WEB_ID]
    item.instance_variable_set('@persisted', true)
    item
  end

  def initialize
    super
    @bytestreams = Set.new
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
      @children = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          order(Solr::Fields::PAGE_NUMBER)
    end
    @children
  end

  alias_method :items, :children

  ##
  # @return [MedusaCollection]
  #
  def collection
    @collection = MedusaCollection.find(self.collection_id) unless @collection
    @collection
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
  # @return [Item] The item's front matter item, if available.
  #
  def front_matter_item
    unless @front_matter_item
      @front_matter_item = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          where(Solr::Fields::SUBCLASS => Item::Subclasses::FRONT_MATTER).
          limit(1).first
    end
    @front_matter_item
  end

  ##
  # @return [Item] The item's index item, if available.
  #
  def index_item
    unless @index_item
      @index_item = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          where(Solr::Fields::SUBCLASS => Item::Subclasses::INDEX).
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
      @key_item = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          where(Solr::Fields::SUBCLASS => Item::Subclasses::KEY).
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
          where(Solr::Fields::PARENT_ITEM => self.parent_id,
                Solr::Fields::PAGE_NUMBER => self.page_number + 1).
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
      @pages = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          where(Solr::Fields::SUBCLASS => Item::Subclasses::PAGE).
          order(Solr::Fields::PAGE_NUMBER)
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
          where(Solr::Fields::PARENT_ITEM => self.parent_id,
                Solr::Fields::PAGE_NUMBER => self.page_number - 1).
          limit(1).first
    end
    prev_item
  end

  ##
  # @return [Item] The item's title item, if available.
  #
  def title_item
    unless @title_item
      @title_item = Item.where(Solr::Fields::PARENT_ITEM => self.id).
          where(Solr::Fields::SUBCLASS => Item::Subclasses::TITLE).
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
    doc[Solr::Fields::COLLECTION] = self.collection_id
    doc[Solr::Fields::PAGE_NUMBER] = self.page_number
    doc[Solr::Fields::PARENT_ITEM] = self.parent_id
    doc[Solr::Fields::DATE] = self.date.utc.iso8601 if self.date
    self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.each do |bs|
      doc[Solr::Fields::ACCESS_MASTER_HEIGHT] = bs.height
      doc[Solr::Fields::ACCESS_MASTER_MEDIA_TYPE] = bs.media_type
      doc[Solr::Fields::ACCESS_MASTER_PATHNAME] = bs.repository_relative_pathname
      doc[Solr::Fields::ACCESS_MASTER_URL] = bs.url
      doc[Solr::Fields::ACCESS_MASTER_WIDTH] = bs.width
    end
    doc[Solr::Fields::FULL_TEXT] = self.full_text
    if self.latitude and self.longitude
      doc[Solr::Fields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.each do |bs|
      doc[Solr::Fields::PRESERVATION_MASTER_HEIGHT] = bs.height
      doc[Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE] = bs.media_type
      doc[Solr::Fields::PRESERVATION_MASTER_PATHNAME] = bs.repository_relative_pathname
      doc[Solr::Fields::PRESERVATION_MASTER_URL] = bs.url
      doc[Solr::Fields::PRESERVATION_MASTER_WIDTH] = bs.width
    end
    doc[Solr::Fields::SUBPAGE_NUMBER] = self.subpage_number
    doc
  end

end
