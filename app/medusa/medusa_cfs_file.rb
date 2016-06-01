class MedusaCfsFile

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  ##
  # @param id [String] Medusa UUID
  # @return [Boolean]
  #
  def self.file?(id)
    url = PearTree::Application.peartree_config[:medusa_url].chomp('/') +
        '/uuids/' + id.to_s + '.json'
    # It's a file if Medusa redirects to a /cfs_files/ URI.
    response = Medusa.client.head(url, follow_redirect: false)
    response.header['Location'].to_s.include?('/cfs_files/')
  end

  ##
  # @return [String]
  #
  def pathname
    PearTree::Application.peartree_config[:repository_pathname].chomp('/') +
        self.repository_relative_pathname
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def reload
    raise 'reload() called without ID set' unless self.id.present?

    json_str = Medusa.client.get(self.url + '.json', follow_redirect: true).body
    unless Rails.env.test?
      FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
      File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    end
    self.medusa_representation = JSON.parse(json_str)
    @loaded = true
  end

  def repository_relative_pathname
    unless @repository_relative_pathname
      load
      @repository_relative_pathname = '/' +
          self.medusa_representation['relative_pathname']
    end
    @repository_relative_pathname
  end

  ##
  # @return [String] Absolute URI of the Medusa file group resource, or nil
  #                  if the instance does not have an ID.
  #
  def url
    url = nil
    if self.id
      url = PearTree::Application.peartree_config[:medusa_url].chomp('/') +
          '/uuids/' + self.id.to_s
    end
    url
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/cfs_file_#{self.id}.json"
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

    if Rails.env.test?
      reload
    else
      ttl = PearTree::Application.peartree_config[:medusa_cache_ttl]
      if File.exist?(cache_pathname) and File.mtime(cache_pathname).
          between?(Time.at(Time.now.to_i - ttl), Time.now)
        json_str = File.read(cache_pathname)
        self.medusa_representation = JSON.parse(json_str)
      else
        reload
      end
    end
    @loaded = true
  end

end
