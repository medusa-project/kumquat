class MedusaCollection

  include ActiveModel::Model
  include GlobalID::Identification

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  def self.all
    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/collections.json"
    response = Medusa.client.get(url)
    struct = JSON.parse(response.body)

    collections = []
    struct.each do |row|
      col = MedusaCollection.new
      col.id = row['id']
      collections << col
    end
    collections
  end

  def self.find(id)
    col = MedusaCollection.new
    col.id = id
    begin
      col.title # this will raise an error if the ID is invalid
    rescue
      raise ActiveRecord::RecordNotFound
    end
    col
  end

  def access_url
    unless @access_url
      load
      @access_url = self.medusa_representation['access_url']
    end
    @access_url
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

  def description
    unless @description
      load
      @description = self.medusa_representation['description']
    end
    @description
  end

  def description_html
    unless @description_html
      load
      @description_html = self.medusa_representation['description_html']
    end
    @description_html
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

  ##
  # @return [Integer]
  #
  def num_items
    @num_items = Item.where(Solr::Fields::COLLECTION => self.id).
        where(Solr::Fields::PARENT_ITEM => :null).count unless @num_items
    @num_items
  end

  ##
  # Makes to_param work.
  #
  def persisted?
    true
  end

  def published
    unless @published
      load
      @published = self.medusa_representation['publish']
    end
    @published
  end

  def published_in_dls
    self.id == '162' # TODO: fix this
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def reload
    raise 'reload() called without ID set' unless self.id
    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/collections/#{self.id}.json"
    json_str = Medusa.client.get(url).body
    FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
    File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    self.medusa_representation = json_str
    @loaded = true
  end

  def representative_image
    unless @representative_image
      load
      @representative_image = self.medusa_representation['representative_image']
    end
    @representative_image
  end

  def representative_item
    Item.find('1607347_001.jp2') # TODO: store this in medusa
  end

  def title
    unless @title
      load
      @title = self.medusa_representation['title']
    end
    @title
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

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/collection_#{self.id}.json"
  end

  ##
  # Populates `medusa_representation`.
  #
  # @return [void]
  # @raises [RuntimeError] If the instance's ID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load
    return if @loaded
    raise 'load() called without ID set' unless self.id

    if File.exist?(cache_pathname) and File.mtime(cache_pathname).
        between?(Time.at(Time.now.to_i - 2592000), Time.now)
      json_str = File.read(cache_pathname)
      self.medusa_representation = JSON.parse(json_str)
    else
      reload
    end
    @loaded = true
  end

end
