class MedusaCfsDirectory

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

  def pathname
    unless @pathname
      load
      @pathname = PearTree::Application.peartree_config[:repository_pathname] +
          '/' + self.medusa_representation['name']
    end
    @pathname
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
