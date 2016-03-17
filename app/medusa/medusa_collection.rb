class MedusaCollection

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

  def access_url
    unless @access_url
      load
      @access_url = self.medusa_representation['access_url']
    end
    @access_url
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

  def published
    unless @published
      load
      @published = self.medusa_representation['publish']
    end
    @published
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
      PearTree::Application.peartree_config[:medusa_url].chomp('/') +
          '/collections/' + self.id
    end
    nil
  end

  private

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

    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/collections/#{self.id}.json"
    self.medusa_representation = JSON.parse(Medusa.client.get(url).body)
    @loaded = true
  end

end
