class MedusaCfsDirectory

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  def pathname
    PearTree::Application.peartree_config[:repository_pathname] +
        self.repository_relative_pathname
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
    url = "#{config[:medusa_url].chomp('/')}/cfs_directories/#{self.id}.json"
    json_str = Medusa.client.get(url).body
    FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
    File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    self.medusa_representation = json_str
    @loaded = true
  end

  def repository_relative_pathname
    unless @repository_relative_pathname
      load
      @repository_relative_pathname = '/' + self.medusa_representation['name']
    end
    @repository_relative_pathname
  end

  ##
  # @return [String] Absolute URI of the Medusa file group resource, or nil
  #                  if the instance does not have an ID.
  #
  def url
    if self.id
      return PearTree::Application.peartree_config[:medusa_url].chomp('/') +
          '/cfs_directories/' + self.id.to_s
    end
    nil
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/cfs_directory_#{self.id}.json"
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
