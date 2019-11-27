##
# Represents a Medusa CFS directory node.
#
# Instances' properties are loaded from Medusa automatically and cached.
# Acquire instances with {with_uuid}.
#
class MedusaCfsDirectory < ApplicationRecord

  LOGGER = CustomLogger.new(MedusaCfsDirectory)

  after_initialize :reset

  ##
  # @param uuid [String]
  # @return [MedusaCfsDirectory]
  #
  def self.with_uuid(uuid)
    dir = MedusaCfsDirectory.find_by_uuid(uuid)
    unless dir
      dir = MedusaCfsDirectory.new
      dir.uuid = uuid
      dir.load_from_medusa
      dir.save!
    end
    dir
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
  # If set to a JSON tree from a Medusa `show_tree.json` endpoint, that will
  # be used instead of making live requests.
  #
  # @param tree [Hash]
  #
  def json_tree=(tree)
    @json_tree = tree
    reset
  end

  ##
  # Updates the instance with current properties from Medusa.
  #
  # @return [void]
  #
  def load_from_medusa
    raise 'load_from_medusa() called without UUID set' unless self.uuid.present?

    client = MedusaClient.instance
    response = client.get(self.url + '.json')

    if response.status < 300
      LOGGER.debug('load_from_medusa(): %s', self.url)
      struct = JSON.parse(response.body)
      self.repository_relative_pathname = "/#{struct['relative_pathname']}"
      self.medusa_database_id = struct['id']
    end
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
    self.repository_relative_pathname
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

  ##
  # @return [void]
  # @raises [RuntimeError] If the instance's ID is not set.
  # @raises [HTTPClient::BadResponseError]
  #
  def load_contents
    return if @contents_loaded
    if @json_tree # This is used in testing to load pre-downloaded fixture data.
      tree = @json_tree
    else
      url = Configuration.instance.medusa_url.chomp('/') +
          '/cfs_directories/' + self.medusa_database_id.to_s + '/show_tree.json'
      LOGGER.debug('load_contents(): %s', url)
      client = MedusaClient.instance
      json_str = client.get(url, follow_redirect: true).body
      tree = JSON.parse(json_str)
    end

    ##
    # Creates a {MedusaCfsDirectory}/{MedusaCfsFile} structure analogous to the
    # given JSON argument.
    #
    # @return [void]
    #
    def assemble_contents(struct, parent_dir = self)
      if struct['subdirectories']
        struct['subdirectories'].each do |struct_dir|
          dir = MedusaCfsDirectory.with_uuid(struct_dir['uuid'])
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
          file = MedusaCfsFile.with_uuid(struct_file['uuid'])
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

  private

  def reset
    @directories = []
    @files = []
    @contents_loaded = false
  end

end
