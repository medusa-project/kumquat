class MedusaFileGroup

  # @!attribute uuid
  #   @return [Integer]
  attr_accessor :uuid

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  def cfs_directory
    unless @cfs_directory
      load
      if self.medusa_representation['cfs_directory']
        @cfs_directory = MedusaCfsDirectory.new
        @cfs_directory.uuid = self.medusa_representation['cfs_directory']['uuid']
      end
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
    raise 'reload() called without UUID set' unless self.uuid.present?

    json_str = Medusa.client.get(self.url + '.json', follow_redirect: true).body
    rep = JSON.parse(json_str)
    if rep['status'].to_i < 300 and !Rails.env.test?
      FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
      File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    end
    self.medusa_representation = rep
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
  # if the instance does not have a UUID.
  #
  def url
    if self.uuid
      return Configuration.instance.medusa_url.chomp('/') +
          '/uuids/' + self.uuid.to_s
    end
    nil
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/file_group_#{self.uuid}.json"
  end

  ##
  # Populates `medusa_representation`.
  #
  # @return [void]
  # @raises [RuntimeError] If the instance's UUID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load
    return if @loaded
    raise 'load() called without UUID set' unless self.uuid.present?

    if Rails.env.test?
      reload
    else
      ttl = Configuration.instance.medusa_cache_ttl
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
