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

    self.medusa_representation =
        JSON.parse(Medusa.client.get("#{self.url}.json").body)
    @loaded = true
  end

end
