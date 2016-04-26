class Item < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    ACCESS_MASTER_HEIGHT = 'access_master_height_ii'
    ACCESS_MASTER_MEDIA_TYPE = 'access_master_media_type_si'
    ACCESS_MASTER_PATHNAME = 'access_master_pathname_si'
    ACCESS_MASTER_URL = 'access_master_url_si'
    ACCESS_MASTER_WIDTH = 'access_master_width_ii'
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
    SUBPAGE_NUMBER = 'subpage_number_ii'
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

  has_many :bytestreams, inverse_of: :item, dependent: :destroy
  has_many :elements, inverse_of: :item, dependent: :destroy

  validates :collection_repository_id, presence: true

  before_destroy :delete_from_solr
  before_save :index_in_solr

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
  # @return [String] Tab-separated values with trailing newline.
  # @see to_tsv
  #
  def self.tsv_header
    # Must remain synchronized with the output of to_tsv.
    tech_elements = ['repositoryId', 'parentId', 'collectionId',
                     'representativeItemId', 'variant', 'pageNumber',
                     'subpageNumber', 'fullText', 'accessMasterPathname',
                     'accessMasterURL', 'accessMasterMediaType',
                     'accessMasterWidth', 'accessMasterHeight',
                     'preservationMasterPathname', 'preservationMasterURL',
                     'preservationMasterMediaType', 'preservationMasterWidth',
                     'preservationMasterHeight', 'created', 'lastModified']
    elements = tech_elements + Element.all_available.
        reject{ |e| tech_elements.include?(e.name) }.map(&:name)
    elements.join("\t") + "\n"
  end

  ##
  # @return [Bytestream]
  #
  def access_master_bytestream
    self.bytestreams.where(bytestream_type: Bytestream::Type::ACCESS_MASTER).
        limit(1).first
  end

  def bib_id
    self.elements.where(name: 'bibId').limit(1)&.first&.value
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
  # @return [Relation] All of the item's children that have a variant of File
  #                    or Directory.
  # @see pages()
  #
  def files
    self.items.where(variant: [Variants::FILE, Variants::DIRECTORY])
  end

  ##
  # @return [Item] The item's key item, if available.
  #
  def front_matter_item
    self.items.where(variant: Variants::FRONT_MATTER).limit(1).first
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
  # @see files()
  #
  def pages
    self.items.where(variant: Variants::PAGE).
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
  #                                 `ItemIngester::SCHEMA_VERSIONS`
  #
  def to_dls_xml(schema_version)
    case schema_version.to_i
      when 1
        return to_dls_xml_v1
      else
        return to_dls_xml_v2
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
    doc[SolrFields::LAST_INDEXED] = self.last_indexed.utc.iso8601
    if self.latitude and self.longitude
      doc[SolrFields::LAT_LONG] = "#{self.latitude},#{self.longitude}"
    end
    doc[SolrFields::PAGE_NUMBER] = self.page_number
    doc[SolrFields::PARENT_ITEM] = self.parent_repository_id
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::REPRESENTATIVE_ITEM_ID] = self.representative_item_repository_id
    doc[SolrFields::SUBPAGE_NUMBER] = self.subpage_number
    doc[SolrFields::VARIANT] = self.variant
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
  # @return [String] Tab-separated values with trailing newline.
  # @see tsv_header
  #
  def to_tsv
    # Columns must remain synchronized with the output of tsv_header. There
    # must also be a fixed number of columns, in order for the CSV schema to
    # be convertible (i.e. to dump large numbers of items at once).
    # Properties with multiple values are placed in the same cell, separated
    # by vertical bar characters.
    columns = []
    columns << self.repository_id
    columns << self.parent_repository_id
    columns << self.collection_repository_id
    columns << self.representative_item_repository_id
    columns << self.variant
    columns << self.page_number
    columns << self.subpage_number
    columns << self.full_text
    bs = self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::ACCESS_MASTER }.first
    columns << bs&.file_group_relative_pathname
    columns << bs&.url
    columns << bs&.media_type
    columns << bs&.width
    columns << bs&.height
    bs = self.bytestreams.
        select{ |b| b.bytestream_type == Bytestream::Type::PRESERVATION_MASTER }.first
    columns << bs&.file_group_relative_pathname
    columns << bs&.url
    columns << bs&.media_type
    columns << bs&.width
    columns << bs&.height
    columns << self.created_at.utc.iso8601
    columns << self.updated_at.utc.iso8601

    Element.all_available.
        select{ |ed| ed.type == Element::Type::DESCRIPTIVE }.each do |el|
      columns << self.elements.select{ |e| e.name == el.name }.map(&:value).
          join('|')
    end
    columns.join("\t") + "\n"
  end

  ##
  # Updates an instance from valid LRP AIP XML.
  #
  # @param [Nokogiri::XML::Node] node
  # @param schema_version [Integer]
  # @return [Item]
  #
  def update_from_xml(node, schema_version = 1)
    case schema_version
      when 1
        namespaces = ItemIngester::XML_V1_NAMESPACE
      else
        namespaces = ItemIngester::XML_V2_NAMESPACE
    end

    ActiveRecord::Base.transaction do
      self.elements.destroy_all
      self.bytestreams.destroy_all

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
      self.latitude = lat.content.strip.to_f if lat

      # longitude
      long = node.xpath('lrp:longitude', namespaces).first
      self.longitude = long.content.strip.to_f if long

      # page number
      page = node.xpath('lrp:pageNumber', namespaces).first
      self.page_number = page.content.strip.to_i if page

      # parent item
      parent = node.xpath('lrp:parentId', namespaces).first
      self.parent_repository_id = parent.content.strip if parent

      # published
      published = node.xpath('lrp:published', namespaces).first
      self.published = %w(true 1).include?(published.content.strip) if published

      # repository ID
      rep_id = node.xpath('lrp:repositoryId', namespaces).first
      self.repository_id = rep_id.content.strip

      # representative item ID
      rep_item_id = node.xpath('lrp:representativeItemId', namespaces).first
      self.representative_item_repository_id = rep_item_id.content.strip if rep_item_id

      if schema_version == 1
        # subclass
        subclass = node.xpath('lrp:subclass', namespaces).first
        self.variant = subclass.content.strip if subclass
      else
        # variant
        variant = node.xpath('lrp:variant', namespaces).first
        self.variant = variant.content.strip if variant
      end

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

  private

  def to_dls_xml_v1
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['lrp'].Object('xmlns:lrp' => ItemIngester::XML_V1_NAMESPACE['lrp']) {
        bib_id = self.elements.find_by_name('bibId')
        if bib_id.present?
          xml['lrp'].bibId {
            xml.text(bib_id)
          }
        end
        if self.created_at.present?
          xml['lrp'].created {
            xml.text(self.created_at.utc.iso8601)
          }
        end
        if self.updated_at.present?
          xml['lrp'].lastModified {
            xml.text(self.updated_at.utc.iso8601)
          }
        end
        xml['lrp'].published {
          xml.text(self.published ? 'true' : 'false')
        }
        xml['lrp'].repositoryId {
          xml.text(self.repository_id)
        }
        if self.representative_item_repository_id.present?
          xml['lrp'].representativeItemId {
            xml.text(self.representative_item_repository_id)
          }
        end

        self.elements.order(:name).each do |element|
          next if element.name == 'bibId'
          if element.value.present?
            xml['lrp'].send(element.name) {
              xml.text(element.value)
            }
          end
        end

        access_master = self.bytestreams.
            where(bytestream_type: Bytestream::Type::ACCESS_MASTER).limit(1).first
        if access_master
          if access_master.height.present?
            xml['lrp'].accessMasterHeight {
              xml.text(access_master.height)
            }
          end
          if access_master.media_type.present?
            xml['lrp'].accessMasterMediaType {
              xml.text(access_master.media_type)
            }
          end
          xml['lrp'].accessMasterPathname {
            xml.text(access_master.repository_relative_pathname)
          }
          if access_master.url.present?
            xml['lrp'].accessMasterURL {
              xml.text(access_master.url)
            }
          end
          if access_master.width.present?
            xml['lrp'].accessMasterWidth {
              xml.text(access_master.width)
            }
          end
        end

        xml['lrp'].collectionId {
          xml.text(self.collection_repository_id)
        }

        if self.full_text.present?
          xml['lrp'].fullText {
            xml.text(self.full_text)
          }
        end
        if self.page_number.present?
          xml['lrp'].pageNumber {
            xml.text(self.page_number)
          }
        end
        if self.parent_repository_id.present?
          xml['lrp'].parentId {
            xml.text(self.parent_repository_id)
          }
        end

        preservation_master = self.bytestreams.
            where(bytestream_type: Bytestream::Type::PRESERVATION_MASTER).
            limit(1).first
        if preservation_master
          if preservation_master.height.present?
            xml['lrp'].preservationMasterHeight {
              xml.text(preservation_master.height)
            }
          end
          if preservation_master.media_type.present?
            xml['lrp'].preservationMasterMediaType {
              xml.text(preservation_master.media_type)
            }
          end
          xml['lrp'].preservationMasterPathname {
            xml.text(preservation_master.repository_relative_pathname)
          }
          if preservation_master.url.present?
            xml['lrp'].preservationMasterURL {
              xml.text(preservation_master.url)
            }
          end
          if preservation_master.width.present?
            xml['lrp'].preservationMasterWidth {
              xml.text(preservation_master.width)
            }
          end
        end

        if self.variant.present?
          xml['lrp'].subclass {
            xml.text(self.variant)
          }
        end

        if self.subpage_number.present?
          xml['lrp'].subpageNumber {
            xml.text(self.subpage_number)
          }
        end
      }
    end
    builder.to_xml
  end

  def to_dls_xml_v2
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['dls'].Object('xmlns:dls' => ItemIngester::XML_V2_NAMESPACE['dls']) {
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

        access_master = self.bytestreams.
            where(bytestream_type: Bytestream::Type::ACCESS_MASTER).limit(1).first
        if access_master
          xml['dls'].accessMasterPathname {
            xml.text(access_master.repository_relative_pathname)
          }
          if access_master.url.present?
            xml['dls'].accessMasterURL {
              xml.text(access_master.url)
            }
          end
          if access_master.media_type.present?
            xml['dls'].accessMasterMediaType {
              xml.text(access_master.media_type)
            }
          end
          if access_master.width.present?
            xml['dls'].accessMasterWidth {
              xml.text(access_master.width)
            }
          end
          if access_master.height.present?
            xml['dls'].accessMasterHeight {
              xml.text(access_master.height)
            }
          end
        end

        preservation_master = self.bytestreams.
            where(bytestream_type: Bytestream::Type::PRESERVATION_MASTER).
            limit(1).first
        if preservation_master
          xml['dls'].preservationMasterPathname {
            xml.text(preservation_master.repository_relative_pathname)
          }
          if preservation_master.url.present?
            xml['dls'].preservationMasterURL {
              xml.text(preservation_master.url)
            }
          end
          if preservation_master.media_type.present?
            xml['dls'].preservationMasterMediaType {
              xml.text(preservation_master.media_type)
            }
          end
          if preservation_master.width.present?
            xml['dls'].preservationMasterWidth {
              xml.text(preservation_master.width)
            }
          end
          if preservation_master.height.present?
            xml['dls'].preservationMasterHeight {
              xml.text(preservation_master.height)
            }
          end
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
