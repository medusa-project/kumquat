class MedusaFileGroup

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  def cfs_directory
    unless @cfs_directory
      load
      @cfs_directory = MedusaCfsDirectory.new
      @cfs_directory.id = self.medusa_representation['cfs_directory']['id']
    end
    @cfs_directory
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def reload
    raise 'reload() called without ID set' unless self.id.present?

    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/file_groups/#{self.id}.json"
    json_str = Medusa.client.get(url).body
    FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
    File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    self.medusa_representation = JSON.parse(json_str)
    @loaded = true
  end

  def title
    unless @title
      load
      @title = self.medusa_representation['title']
    end
    @title
  end

  ##
  # @return [String] Absolute URI of the Medusa file group resource, or nil
  # if the instance does not have an ID.
  #
  def url
    if self.id
      return PearTree::Application.peartree_config[:medusa_url].chomp('/') +
          '/file_groups/' + self.id.to_s
    end
    nil
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/file_group_#{self.id}.json"
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
    raise 'load() called without ID set' unless self.id.present?

    ttl = PearTree::Application.peartree_config[:medusa_cache_ttl]
    if File.exist?(cache_pathname) and File.mtime(cache_pathname).
        between?(Time.at(Time.now.to_i - ttl), Time.now)
      json_str = File.read(cache_pathname)
      self.medusa_representation = JSON.parse(json_str)
    else
      reload
    end
    @loaded = true
  end

end
