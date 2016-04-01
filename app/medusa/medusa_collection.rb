class MedusaCollection < Entity

  class SolrFields
    ACCESS_URL = 'access_url_si'
    DESCRIPTION = 'description_txti'
    DESCRIPTION_HTML = 'description_html_txti'
    PUBLISHED = 'published_bi'
    PUBLISHED_IN_DLS = 'published_in_dls_bi'
    REPRESENTATIVE_IMAGE = 'representative_image_si'
    REPRESENTATIVE_ITEM = 'representative_item_si'
    TITLE = 'title_txti'
  end

  # @!attribute access_url
  #   @return [String]
  attr_accessor :access_url

  # @!attribute description
  #   @return [String]
  attr_accessor :description

  # @!attribute description
  #   @return [String]
  attr_accessor :description_html

  # @!attribute published
  #   @return [Boolean]
  attr_accessor :published

  # @!attribute published_in_dls
  #   @return [Boolean]
  attr_accessor :published_in_dls

  # @!attribute representative_image
  #   @return [String]
  attr_accessor :representative_image

  # @!attribute representative_item
  #   @return [String]
  attr_accessor :representative_item

  # @!attribute title
  #   @return [String]
  attr_accessor :title

  ##
  # @param struct [Hash] Hash from the Medusa JSON response
  # @return [MedusaCollection]
  #
  def self.from_medusa(struct)
    col = MedusaCollection.new
    col.id = struct['id']
    col.load_from_medusa
    col
  end

  ##
  # @param doc [Nokogiri::XML::Document]
  # @return [Item]
  #
  def self.from_solr(doc)
    col = MedusaCollection.new

    col.id = doc[Entity::SolrFields::ID]
    col.access_url = doc[SolrFields::ACCESS_URL]
    col.description = doc[SolrFields::DESCRIPTION]
    col.description_html = doc[SolrFields::DESCRIPTION_HTML]
    if doc[Entity::SolrFields::LAST_INDEXED]
      col.last_indexed = Time.parse(doc[Entity::SolrFields::LAST_INDEXED])
    end
    col.published = doc[SolrFields::PUBLISHED]
    col.published_in_dls = doc[SolrFields::PUBLISHED_IN_DLS]
    col.title = doc[SolrFields::TITLE]

    col.instance_variable_set('@persisted', true)
    col
  end

  ##
  # @return [CollectionDef]
  #
  def collection_def
    unless @collection_def
      @collection_def = CollectionDef.find_by_repository_id(self.id) ||
          CollectionDef.create!(repository_id: self.id,
                                metadata_profile: MetadataProfile.find_by_default(true))
    end
    @collection_def
  end

  def file_groups
    unless @file_groups
      load
      self.medusa_representation['file_groups'].each do |row|
        @file_groups << MedusaFileGroup.new{
          self.id = row['id']
          self.pathname = row['path']
          self.title = row['title']
          self.storage_level = row['storage_level']
        }
      end
    end
    @file_groups
  end

  def load_from_medusa
    raise 'load() called without ID set' unless self.id

    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/collections/#{self.id}.json"
    json_str = Medusa.client.get(url).body
    struct = JSON.parse(json_str)

    self.access_url = struct['access_url']
    self.description = struct['description']
    self.description_html = struct['description_html']
    self.published = struct['publish']
    self.published_in_dls = struct['published_in_dls']
    self.representative_image = struct['representative_image']
    self.representative_item = struct['representative_item']
    self.title = struct['title']
  end

  ##
  # @return [Integer]
  #
  def num_items
    @num_items = Item.where(Item::SolrFields::COLLECTION => self.id).
        where(Item::SolrFields::PARENT_ITEM => :null).count unless @num_items
    @num_items
  end

  ##
  # Makes to_param work.
  #
  def persisted?
    true
  end

  def published_in_dls
    self.id.to_s == '162' # TODO: eliminate this
  end

  def representative_item # TODO: eliminate this
    if self.id.to_s == '162'
      return Item.find('1607347_001.jp2')
    end
    nil
  end

  ##
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  # if the instance does not have an ID.
  #
  def url
    if self.id
      return PearTree::Application.peartree_config[:medusa_url].chomp('/') +
          '/collections/' + self.id.to_s
    end
    nil
  end

  ##
  # Overrides parent
  #
  # @return [Hash]
  #
  def to_solr
    doc = super
    doc[SolrFields::ACCESS_URL] = self.access_url
    doc[SolrFields::DESCRIPTION] = self.description
    doc[SolrFields::DESCRIPTION_HTML] = self.description_html
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[SolrFields::TITLE] = self.title
    doc
  end

end
