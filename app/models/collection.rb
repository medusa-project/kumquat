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
    REPOSITORY_TITLE = 'repository_title_si'
    REPRESENTATIVE_IMAGE = 'representative_image_si'
    REPRESENTATIVE_ITEM = 'representative_item_si'
    RESOURCE_TYPES = 'resource_types_sim'
    SEARCH_ALL = 'searchall_txtim'
    TITLE = 'title_sort_en_i'
  end

  serialize :resource_types

  belongs_to :metadata_profile, inverse_of: :collections
  belongs_to :theme, inverse_of: :collections
  has_many :element_defs, inverse_of: :collection

  validates :repository_id, presence: true

  after_commit :index_in_solr, on: [:create, :update]
  after_commit :delete_from_solr, on: :destroy

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

  ##
  # @return [Array<Hash>] Array of hashes with `:name` and `:label` keys
  #
  def self.solr_facet_fields
    [ { name: SolrFields::REPOSITORY_TITLE, label: 'Repository' },
      { name: SolrFields::RESOURCE_TYPES, label: 'Resource Type' } ]
  end

  def delete_from_solr
    Solr.instance.delete(self.solr_id)
  end

  ##
  # The effective CFS directory of the instance -- either one that is directly
  # assigned, or the root CFS directory of the file group.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see medusa_cfs_directory
  #
  def effective_medusa_cfs_directory
    self.medusa_cfs_directory || self.medusa_file_group&.cfs_directory
  end

  def effective_metadata_profile
    self.metadata_profile || MetadataProfile.default
  end

  def index_in_solr
    Solr.instance.add(self.to_solr)
  end

  ##
  # The CFS directory in which content resides. This may be the same as the
  # root CFS directory of the file group, or deeper within it. This is used
  # as a refinement of medusa_file_group.
  #
  # @return [MedusaCfsDirectory, nil]
  # @see effective_medusa_cfs_directory
  #
  def medusa_cfs_directory
    unless @cfs_directory
      @cfs_directory = nil
      if self.medusa_cfs_directory_id
        @cfs_directory = MedusaCfsDirectory.new
        @cfs_directory.id = self.medusa_cfs_directory_id
      end
    end
    @cfs_directory
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
  # @param format [String] URL extension like `json`
  # @return [String] Absolute URI of the Medusa collection resource, or nil
  #                  if the instance does not have an ID.
  #
  def medusa_url(format = nil)
    format = format.present? ? ".#{format.to_s.gsub('.', '')}" : ''
    url = nil
    if self.repository_id
      url = sprintf('%s/collections/%s%s',
                    PearTree::Application.peartree_config[:medusa_url].chomp('/'),
                    self.repository_id,
                    format)
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

  ##
  # @return [Bytestream,nil] Best representative image bytestream based on the
  #                          representative item set in Medusa, if available,
  #                          or the representative image, if not.
  #
  def representative_image_bytestream
    bs = nil
    if self.representative_item
      item = self.representative_item
      bs = item.access_master_bytestream || item.preservation_master_bytestream
    elsif self.representative_image.present?
      cfs_file = MedusaCfsFile.new
      cfs_file.id = self.representative_image
      bs = Bytestream.new
      bs.file_group_relative_pathname = cfs_file.repository_relative_pathname
      bs.infer_media_type
    end
    bs
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
    json_str = Medusa.client.get(self.medusa_url('json')).body
    struct = JSON.parse(json_str)

    self.access_url = struct['access_url']
    self.description = struct['description']
    self.description_html = struct['description_html']
    self.published = struct['publish']
    self.published_in_dls = struct['access_systems'].
        select{ |obj| obj['name'].include?('Medusa Digital Library') }.any?
    self.repository_title = struct['repository_title']
    self.representative_image = struct['representative_image']
    self.representative_item_id = struct['representative_item']
    self.resource_types = struct['resource_types'].map{ |t| t['name'] }
    self.title = struct['title']
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
    doc[SolrFields::LAST_INDEXED] = Time.now.utc.iso8601
    doc[SolrFields::ACCESS_URL] = self.access_url
    doc[SolrFields::DESCRIPTION] = self.description
    doc[SolrFields::DESCRIPTION_HTML] = self.description_html
    doc[SolrFields::PUBLISHED] = self.published
    doc[SolrFields::PUBLISHED_IN_DLS] = self.published_in_dls
    doc[SolrFields::REPOSITORY_TITLE] = self.repository_title
    doc[SolrFields::REPRESENTATIVE_ITEM] = self.representative_item_id
    doc[SolrFields::RESOURCE_TYPES] = self.resource_types
    doc[SolrFields::TITLE] = self.title
    doc
  end

end
