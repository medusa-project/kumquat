class MedusaCfsDirectory

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  # @!attribute uuid
  #   @return [Integer]
  attr_accessor :uuid

  def initialize
    reset
  end

  ##
  # @return [Enumerable<MedusaCfsDirectory>]
  #
  def directories
    load_contents
    @directories
  end

  ##
  # @return [Enumerable<MedusaCfsFile>]
  #
  def files
    load_contents
    @files
  end

  ##
  # @return [Integer] Database ID of the entity.
  #
  def id
    load_instance
    self.medusa_representation['id']
  end

  ##
  # If set to a JSON tree from a Medusa show_tree.json endpoint, that will
  # be used instead of making live requests.
  #
  # @param tree [Hash]
  #
  def json_tree=(tree)
    @json_tree = tree
    reset
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

    url = self.url + '.json'
    CustomLogger.instance.debug('MedusaCfsDirectory.reload_instance: loading ' + url)

    client = MedusaClient.new
    response = client.get(self.url + '.json')
    json_str = response.body
    if response.status < 300 and !Rails.env.test?
      FileUtils.mkdir_p("#{Rails.root}/tmp/cache/medusa")
      File.open(cache_pathname, 'wb') { |f| f.write(json_str) }
    end
    self.medusa_representation = JSON.parse(json_str)
    @instance_loaded = true
  end

  def repository_relative_pathname
    unless @repository_relative_pathname
      load_instance
      @repository_relative_pathname = "/#{self.medusa_representation['relative_pathname']}"
    end
    @repository_relative_pathname
  end

  def to_s
    "#{self.uuid} #{self.repository_relative_pathname}"
  end

  ##
  # @return [String] Absolute URI of the Medusa CFS directory resource, or nil
  #                  if the instance does not have a UUID.
  #
  def url
    if self.uuid
      return Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
          self.uuid.to_s
    end
    nil
  end

  private

  def cache_pathname
    "#{Rails.root}/tmp/cache/medusa/cfs_directory_#{self.uuid}.json"
  end

  ##
  # @return [void]
  # @raises [RuntimeError] If the instance's ID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load_contents
    return if @contents_loaded
    if @json_tree # This will likely only be true during testing.
      tree = @json_tree
    else
      url = Configuration.instance.medusa_url.chomp('/') +
          '/cfs_directories/' + self.id.to_s + '/show_tree.json'
      CustomLogger.instance.debug('MedusaCfsDirectory.load_contents(): loading ' + url)
      client = MedusaClient.new
      json_str = client.get(url, follow_redirect: true).body
      tree = JSON.parse(json_str)
    end

    ##
    # Creates a MedusaCfsDirectory/MedusaCfsFile structure analogous to the
    # given JSON argument.
    #
    # @return [void]
    #
    def assemble_contents(struct, parent_dir = self)
      if struct['subdirectories']
        struct['subdirectories'].each do |struct_dir|
          dir = MedusaCfsDirectory.new
          dir.uuid = struct_dir['uuid']
          # Calling the directories() getter here would cause an infinite loop.
          parent_dir.instance_variable_get('@directories') << dir
          dir.instance_variable_set('@contents_loaded', true)
          dir.instance_variable_set('@repository_relative_pathname',
                                    struct_dir['relative_pathname'])
          assemble_contents(struct_dir, dir)
        end
      end
      if struct['files']
        struct['files'].each do |struct_file|
          file = MedusaCfsFile.new
          file.uuid = struct_file['uuid']
          # Calling the files() getter here would cause an infinite loop.
          parent_dir.instance_variable_get('@files') << file
          file.instance_variable_set('@repository_relative_pathname',
                                     struct_file['relative_pathname'])
        end
      end
    end

    assemble_contents(tree)
    @contents_loaded = true
    nil
  end

  ##
  # Populates `medusa_representation` with the instance's Medusa
  # representation.
  #
  # @return [void]
  # @raises [RuntimeError] If the instance's ID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load_instance
    return if @instance_loaded
    raise 'load_instance() called without ID set' unless self.uuid.present?

    ttl = Configuration.instance.medusa_cache_ttl
    if File.exist?(cache_pathname) and File.mtime(cache_pathname).
        between?(Time.at(Time.now.to_i - ttl), Time.now)
      json_str = File.read(cache_pathname)
      self.medusa_representation = JSON.parse(json_str)
    else
      reload_instance
    end
    @instance_loaded = true
  end

  def reset
    @directories = []
    @files = []
    @contents_loaded = false
  end

end
