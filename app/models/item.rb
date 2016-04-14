class Item < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    ACCESS_MASTER_HEIGHT = 'access_master_height_ii'
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
    ACCESS_MASTER_URL = 'access_master_url_si'
    ACCESS_MASTER_WIDTH = 'access_master_width_ii'
    BIB_ID = 'bib_id_si'
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

  has_many :bytestreams, inverse_of: :item, dependent: :destroy
  has_many :elements, inverse_of: :item, dependent: :destroy

  validates :collection_repository_id, presence: true

  before_destroy :delete_from_solr
  before_save :index_in_solr

  ##
  # Creates a new instance from valid LRP AIP XML, persists it, and returns it.
  #
  # @param [Nokogiri::XML::Node] node
  # @return [Item]
  #
  def self.from_lrp_xml(node)
    item = Item.new
    item.update_from_xml(node)
    item
  end

  ##
  # @return [Bytestream]
  #
  def access_master_bytestream
    self.bytestreams.where(bytestream_type: Bytestream::Type::ACCESS_MASTER).
        limit(1).first
  end

  ##
  # @return [Collection]
  #
  def collection
    Collection.find_by_repository_id(self.collection_repository_id)
  end

  ##
  # @return [Element]
  #
  def description
    element = self.elements.where(name: 'description').limit(1).first
    element ? element.value : nil
  end

  def delete_from_solr
    self.last_indexed = Time.now
    Solr.instance.delete(self.solr_id)
  end

  ##
  # @return [Item]
  # @see representative_item
  #
  def effective_representative_item
    self.representative_item || self
  end

  ##
  # @return [Relation] All of the item's children that have a subclass of File
  #                    or Directory.
  # @see pages()
  #
  def files
    self.items.where(subclass: [Subclasses::FILE, Subclasses::DIRECTORY])
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def front_matter_item
    self.items.where(subclass: Subclasses::FRONT_MATTER).limit(1).first
  end

  def index_in_solr
    self.last_indexed = Time.now
    Solr.instance.add(self.to_solr)
    # To improve the performance of imports, we will avoid saving here, as
    # this will be called in a before_save callback 99.99% of the time.
  end

  ##
  # @return [Item] The item's index item, if available.
  #
  def index_item
    self.items.where(subclass: Subclasses::INDEX).limit(1).first
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
    self.items.where(subclass: Subclasses::KEY).limit(1).first
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
  # @see files()
  #
  def pages
    self.items.where(subclass: Subclasses::PAGE).
        order(:page_number, :subpage_number)
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
        where(bytestream_type: Bytestream::Type::PRESERVATION_MASTER).
        limit(1).first
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
  # @return [Item, nil]
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
    element = self.elements.where(name: 'alternativeTitle').limit(1).first
    element ? element.value : nil
  end

  ##
  # @return [Element]
  #
  def title
    element = self.elements.where(name: 'title').limit(1).first
    element ? element.value : nil
  end

  ##
  # @return [Item] The item's title item, if available.
  #
  def title_item
    self.items.where(subclass: Subclasses::TITLE).limit(1).first
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
    doc[SolrFields::BIB_ID] = self.bib_id
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::COLLECTION] = self.collection_repository_id
    doc[SolrFields::DATE] = self.date.utc.iso8601 if self.date
    doc[SolrFields::FULL_TEXT] = self.full_text
    doc[SolrFields::LAST_INDEXED] = self.last_indexed.utc.iso8601
    if self.latitude and self.longitude
      doc[SolrFields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    doc[SolrFields::PAGE_NUMBER] = self.page_number
    doc[SolrFields::PARENT_ITEM] = self.parent_repository_id
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::REPRESENTATIVE_ITEM_ID] = self.representative_item_repository_id
    doc[SolrFields::SUBCLASS] = self.subclass
    doc[SolrFields::SUBPAGE_NUMBER] = self.subpage_number
    self.bytestreams.where(bytestream_type: Bytestream::Type::ACCESS_MASTER).limit(1).each do |bs|
      doc[SolrFields::ACCESS_MASTER_HEIGHT] = bs.height
      doc[SolrFields::ACCESS_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::ACCESS_MASTER_PATHNAME] = bs.file_group_relative_pathname
      doc[SolrFields::ACCESS_MASTER_URL] = bs.url
      doc[SolrFields::ACCESS_MASTER_WIDTH] = bs.width
    end
    self.bytestreams.where(bytestream_type: Bytestream::Type::PRESERVATION_MASTER).limit(1).each do |bs|
      doc[SolrFields::PRESERVATION_MASTER_HEIGHT] = bs.height
      doc[SolrFields::PRESERVATION_MASTER_MEDIA_TYPE] = bs.media_type
      doc[SolrFields::PRESERVATION_MASTER_PATHNAME] = bs.file_group_relative_pathname
      doc[SolrFields::PRESERVATION_MASTER_URL] = bs.url
      doc[SolrFields::PRESERVATION_MASTER_WIDTH] = bs.width
    end
    self.elements.each do |element|
      doc[element.solr_multi_valued_field] ||= []
      doc[element.solr_multi_valued_field] << element.value
      doc[element.solr_single_valued_field] = element.value
    end

    doc
  end

  ##
  # Updates an instance from valid LRP AIP XML.
  #
  # @param [Nokogiri::XML::Node] node
  # @return [Item]
  #
  def update_from_xml(node)
    namespaces = ItemIngester::XML_NAMESPACES

    ActiveRecord::Base.transaction do
      self.elements.destroy_all
      self.bytestreams.destroy_all

      # bib ID
      bib_id = node.xpath('lrp:bibId', namespaces).first
      self.bib_id = bib_id ? bib_id.content.strip : nil

      # collection
      col_id = node.xpath('lrp:collectionId', namespaces).first
      self.collection_repository_id = col_id.content.strip if col_id

      # date
      date = node.xpath('lrp:date', namespaces).first
      date = node.xpath('lrp:dateCreated', namespaces).first unless date
      if date
        date = date.content.strip
        iso8601 = nil
        # This is rather quick & dirty, but will work for now.
        if date.match('[1-9]{4}') # date is apparently YYYY (1000-)
          iso8601 = "#{date}-01-01T00:00:00Z"
        elsif date.match('[1-9]{4}-[0-1][0-9]-[0-3][0-9]') # date is apparently YYYY-MM-DD
          iso8601 = "#{date}T00:00:00Z"
        end
        if iso8601
          self.date = Time.parse(iso8601)
        end
      end

      # full text
      id = node.xpath('lrp:fullText', namespaces).first
      self.full_text = id.content.strip if id

      # latitude
      lat = node.xpath('lrp:latitude', namespaces).first
      self.latitude = lat ? lat.content.strip.to_f : nil

      # longitude
      long = node.xpath('lrp:longitude', namespaces).first
      self.longitude = long ? long.content.strip.to_f : nil

      # page number
      page = node.xpath('lrp:pageNumber', namespaces).first
      self.page_number = page.content.strip.to_i if page

      # parent item
      parent = node.xpath('lrp:parentId', namespaces).first
      self.parent_repository_id = parent.content.strip if parent

      # published
      published = node.xpath('lrp:published', namespaces).first
      self.published = published ?
          %w(true 1).include?(published.content.strip) : false

      # repository ID
      rep_id = node.xpath('lrp:repositoryId', namespaces).first
      self.repository_id = rep_id.content.strip

      # representative item ID
      rep_item_id = node.xpath('lrp:representativeItemId', namespaces).first
      self.representative_item_repository_id = rep_item_id.content.strip if rep_item_id

      # subclass
      subclass = node.xpath('lrp:subclass', namespaces).first
      self.subclass = subclass ? subclass.content.strip : nil

      # subpage number
      page = node.xpath('lrp:subpageNumber', namespaces).first
      self.subpage_number = page.content.strip.to_i if page

      # access master (pathname)
      am = node.xpath('lrp:accessMasterPathname', namespaces).first
      if am
        bs = self.bytestreams.build
        bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
        bs.file_group_relative_pathname = am.content.strip
        # width
        width = node.xpath('lrp:accessMasterWidth', namespaces).first
        bs.width = width.content.strip.to_i if width
        # height
        height = node.xpath('lrp:accessMasterHeight', namespaces).first
        bs.height = height.content.strip.to_i if height
        # media type
        mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
        bs.media_type = mt.content.strip if mt
        bs.save!
      else # access master (URL)
        am = node.xpath('lrp:accessMasterURL', namespaces).first
        if am
          bs = self.bytestreams.build
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.url = am.content.strip
          # media type
          mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
          bs.media_type = mt.content.strip if mt
          bs.save!
        end
      end

      # preservation master (pathname)
      pm = node.xpath('lrp:preservationMasterPathname', namespaces).first
      if pm
        bs = self.bytestreams.build
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.file_group_relative_pathname = pm.content.strip
        mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
        bs.media_type = mt.content.strip if mt
        bs.save!
      else # preservation master (URL)
        pm = node.xpath('lrp:preservationMasterURL', namespaces).first
        if pm
          bs = self.bytestreams.build
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.url = pm.content.strip
          # width
          width = node.xpath('lrp:preservationMasterWidth', namespaces).first
          bs.width = width.content.strip.to_i if width
          # height
          height = node.xpath('lrp:preservationMasterHeight', namespaces).first
          bs.height = height.content.strip.to_i if height
          # media type
          mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
          bs.media_type = mt.content.strip if mt
          bs.save!
        end
      end

      descriptive_elements = Element.all_available.
          select{ |e| e.type == Element::Type::DESCRIPTIVE }.map(&:name)
      node.xpath('lrp:*', namespaces).each do |md_node|
        if descriptive_elements.include?(md_node.name)
          e = Element.named(md_node.name)
          e.value = md_node.content.strip
          self.elements << e
        end
      end

      self.save!
    end
  end

end
