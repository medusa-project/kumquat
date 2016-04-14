##
# Serialization is handled in CollectionSerializer.
#
class Collection < ActiveRecord::Base

  include SolrQuerying

  class SolrFields
    ACCESS_URL = 'access_url_si'
    CLASS = 'class_si'
    DESCRIPTION = 'description_txti'
    DESCRIPTION_HTML = 'description_html_txti'
    ID = 'id'
    LAST_INDEXED = 'last_indexed_dti'
    PUBLISHED = 'published_bi'
    PUBLISHED_IN_DLS = 'published_in_dls_bi'
    REPRESENTATIVE_IMAGE = 'representative_image_si'
    REPRESENTATIVE_ITEM = 'representative_item_si'
    SEARCH_ALL = 'searchall_txtim'
    TITLE = 'title_sort_en_i'
  end

  belongs_to :metadata_profile, inverse_of: :collections
  belongs_to :theme, inverse_of: :collections
  has_many :element_defs, inverse_of: :collection

  validates :repository_id, presence: true

  validates_uniqueness_of :repository_id

  before_destroy :delete_from_solr
  before_save :index_in_solr

  ##
  # @param id [Integer] Medusa collection ID
  # @return [Collection]
  #
  def self.from_medusa(id)
    col = Collection.new
    col.repository_id = id
    col.update_from_medusa
    col
  end

  def delete_from_solr
    self.last_indexed = Time.now
    Solr.instance.delete(self.solr_id)
  end

  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  def file_groups
    unless @file_groups
      load
      self.medusa_representation['file_groups'].each do |row|
        fg = MedusaFileGroup.new
        fg.id = row['id']
        fg.pathname = row['path']
        fg.title = row['title']
        fg.storage_level = row['storage_level']
        @file_groups << fg
      end
    end
    @file_groups
  end

  def index_in_solr
    self.last_indexed = Time.now
    Solr.instance.add(self.to_solr)
  end

  def medusa_file_group
   unless @file_group
     @file_group = nil
     if self.medusa_file_group_id
       @file_group = MedusaFileGroup.new
       @file_group.id = self.medusa_file_group_id
     end
   end
   @file_group
  end

  ##
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  # if the instance does not have an ID.
  #
  def medusa_url
    url = nil
    if self.repository_id
      url = sprintf('%s/collections/%s.json',
              PearTree::Application.peartree_config[:medusa_url].chomp('/'),
              self.repository_id)
    end
    url
  end

  ##
  # @return [Integer]
  #
  def num_items
    @num_items = Item.where(Item::SolrFields::COLLECTION => self.repository_id).
        where(Item::SolrFields::PARENT_ITEM => :null).count unless @num_items
    @num_items
  end

  def representative_item
    item = nil
    if self.representative_item_id.present?
      item = Item.find_by_repository_id(self.representative_item_id)
    end
    item
  end

  def solr_id
    self.repository_id
  end

  def to_param
    self.repository_id
  end

  def to_s
    self.title
  end

  def update_from_medusa
    unless self.repository_id
      raise 'update_from_medusa() called without repository_id set'
    end
    json_str = Medusa.client.get(self.medusa_url).body
    struct = JSON.parse(json_str)

    self.access_url = struct['access_url']
    self.description = struct['description']
    self.description_html = struct['description_html']
    self.published = struct['publish']
    self.published_in_dls = struct['access_systems'].
        select{ |obj| obj['name'].include?('Medusa Digital Library') }.any?
    self.representative_image = struct['representative_image']
    self.representative_item_id = struct['representative_item']
    self.title = struct['title']
  end

  def url # TODO: replace with medusa_url
    medusa_url
  end

  ##
  # Overrides parent
  #
  # @return [Hash]
  #
  def to_solr
    doc = {}
    doc[SolrFields::ID] = self.solr_id
    doc[SolrFields::CLASS] = self.class.to_s
    doc[SolrFields::LAST_INDEXED] = self.last_indexed.utc.iso8601
    doc[SolrFields::ACCESS_URL] = self.access_url
    doc[SolrFields::DESCRIPTION] = self.description
    doc[SolrFields::DESCRIPTION_HTML] = self.description_html
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[SolrFields::REPRESENTATIVE_ITEM] = self.representative_item_id
    doc[SolrFields::TITLE] = self.title
    doc
  end

end
