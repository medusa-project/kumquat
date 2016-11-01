class MedusaCfsFile

  # @!attribute uuid
  #   @return [Integer]
  attr_accessor :uuid

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  ##
  # @param uuid [String] Medusa UUID
  # @return [Boolean]
  #
  def self.file?(uuid)
    url = Configuration.instance.medusa_url.chomp('/') +
        '/uuids/' + uuid.to_s + '.json'
    # It's a file if Medusa redirects to a /cfs_files/ URI.
    response = Medusa.client.head(url, follow_redirect: false)
    response.header['Location'].to_s.include?('/cfs_files/')
  end

  ##
  # @return [String]
  #
  def media_type
    load_instance
    self.medusa_representation['content_type']
  end

  ##
  # @return [String]
  #
  def name
    File.basename(self.pathname)
  end

  ##
  # @return [String]
  #
  def pathname
    Configuration.instance.repository_pathname.chomp('/') +
        self.repository_relative_pathname
  end

  ##
  # Downloads and caches the instance's Medusa representation and populates
  # the instance with it.
  #
  # @return [void]
  #
  def reload_instance
    raise 'reload_instance() called without UUID set' unless self.uuid.present?

    json_str = Medusa.client.get(self.url + '.json', follow_redirect: true).body
    rep = JSON.parse(json_str)
    if rep['status'].to_i < 300 and !Rails.env.test?
      FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
      File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    end
    self.medusa_representation = rep
    @instance_loaded = true
  end

  def repository_relative_pathname
    unless @repository_relative_pathname
      load_instance
      @repository_relative_pathname =
          "/#{self.medusa_representation['relative_pathname']}"
    end
    @repository_relative_pathname
  end

  ##
  # @param bytestream_type [Bytestream::Type]
  # @return [Bytestream] Fully initialized bytestream instance (not persisted).
  #
  def to_bytestream(bytestream_type)
    bs = Bytestream.new
    bs.bytestream_type = bytestream_type
    bs.cfs_file_uuid = self.uuid
    bs.repository_relative_pathname =
        '/' + self.repository_relative_pathname.reverse.chomp('/').reverse
    bs.byte_size = File.size(bs.absolute_local_pathname)
    bs.infer_media_type # The type of the CFS file is likely to be vague.
    bs.read_dimensions
    bs
  end

  ##
  # @return [String] Absolute URI of the Medusa CFS file resource, or nil if
  #                  the instance does not have a UUID.
  #
  def url
    url = nil
    if self.uuid
      url = Configuration.instance.medusa_url.chomp('/') +
          '/uuids/' + self.uuid.to_s.strip
    end
    url
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/cfs_file_#{self.uuid}.json"
  end

  ##
  # Populates `medusa_representation`.
  #
  # @return [void]
  # @raises [RuntimeError] If the instance's UUID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load_instance
    return if @instance_loaded
    raise 'load_instance() called without UUID set' unless self.uuid.present?

    if Rails.env.test?
      reload_instance
    else
      ttl = Configuration.instance.medusa_cache_ttl
      if File.exist?(cache_pathname) and File.mtime(cache_pathname).
          between?(Time.at(Time.now.to_i - ttl), Time.now)
        json_str = File.read(cache_pathname)
        self.medusa_representation = JSON.parse(json_str)
      else
        reload_instance
      end
    end
    @instance_loaded = true
  end

end
