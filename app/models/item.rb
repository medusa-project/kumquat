class Item < Entity

  attr_accessor :bytestreams # Set
  attr_accessor :collection_id # String
  attr_accessor :full_text # String
  attr_accessor :parent_id # String

  def self.from_solr(doc)
    item = Item.new
    item.id = doc[Solr::Fields::ID]
    item.parent_id = doc[Solr::Fields::PARENT_ITEM]
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

    # descriptive metadata
    doc.keys.select{ |k| k.start_with?('metadata_') }.each do |key|
      filtered_key = key.gsub('metadata_', '').chomp('_txtim')
      doc[key].each do |value|
        e = Element.named(filtered_key)
        e.value = value
        item.metadata << e
      end
    end
=begin TODO: give technical metadata a field prefix, otherwise this is too error-prone
    # technical metadata
    doc.keys.reject{ |k| k.start_with?('metadata_') or k.end_with?('_facet') }.each do |key|
      if doc[key].respond_to?(:each)
        doc[key].each do |value|
          e = Element.named(key)
          e.value = value
          item.metadata << e
        end
      else
        e = Element.named(key)
        if !e
          e = Element.new
          e.type = Element::Type::TECHNICAL
          e.name = key
        end
        e.value = doc[key]
        item.metadata << e
      end
    end
=end
    item.published = doc[Solr::Fields::PUBLISHED]
    item.title = doc[Solr::Fields::TITLE]
    item.web_id = doc[Solr::Fields::WEB_ID]
    item.instance_variable_set('@persisted', true)
    item
  end

  def initialize
    super
    @bytestreams = Set.new
  end

  def children
    @children = Item.where(Solr::Fields::PARENT_ITEM => self.id) unless @children
    @children
  end

  alias_method :items, :children

  def collection
    @collection = Collection.find(self.collection_id) unless @collection
    @collection
  end

  ##
  # @return [Boolean] True if any text was extracted; false if not
  #
  def extract_and_update_full_text
    if self.master_bytestream and self.master_bytestream.id
      begin
        yomu = Yomu.new(self.master_bytestream.id)
        self.full_text = yomu.text.force_encoding('UTF-8')
      rescue Errno::EPIPE
        return false # nothing we can do
      else
        return self.full_text.present?
      end
    end
    false
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
  # @return [Relation]
  #
  def more_like_this
    Relation.new(self).more_like_this
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

  ##
  # Overrides parent
  #
  # @return [Hash]
  #
  def to_solr
    doc = super
    doc[Solr::Fields::COLLECTION] = self.collection_id
    doc[Solr::Fields::PARENT_ITEM] = self.parent_id
    doc[Solr::Fields::DATE] = self.date.utc.iso8601 + 'Z' if self.date
    self.bytestreams.select{ |b| b.type == Bytestream::Type::ACCESS_MASTER }.each do |bs|
      doc[Solr::Fields::ACCESS_MASTER_HEIGHT] = bs.height
      doc[Solr::Fields::ACCESS_MASTER_MEDIA_TYPE] = bs.media_type
      doc[Solr::Fields::ACCESS_MASTER_PATHNAME] = bs.repository_relative_pathname
      doc[Solr::Fields::ACCESS_MASTER_URL] = bs.url
      doc[Solr::Fields::ACCESS_MASTER_WIDTH] = bs.width
    end
    doc[Solr::Fields::FULL_TEXT] = self.full_text
    self.bytestreams.select{ |b| b.type == Bytestream::Type::PRESERVATION_MASTER }.each do |bs|
      doc[Solr::Fields::PRESERVATION_MASTER_HEIGHT] = bs.height
      doc[Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE] = bs.media_type
      doc[Solr::Fields::PRESERVATION_MASTER_PATHNAME] = bs.repository_relative_pathname
      doc[Solr::Fields::PRESERVATION_MASTER_URL] = bs.url
      doc[Solr::Fields::PRESERVATION_MASTER_WIDTH] = bs.width
    end
    doc
  end

end
