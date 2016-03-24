class MedusaFileGroup

  # @!attribute id
  #   @return [Integer]
  attr_accessor :id

  # @!attribute medusa_representation
  #   @return [Hash]
  attr_accessor :medusa_representation

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
  # @return void
  # @raises [RuntimeError] If the instance's ID is not set
  # @raises [HTTPClient::BadResponseError]
  #
  def load
    return if @loaded
    raise 'load() called without ID set' unless self.id

    config = PearTree::Application.peartree_config
    url = "#{config[:medusa_url].chomp('/')}/bit_level_file_groups/#{self.id}.json"
    self.medusa_representation = JSON.parse(Medusa.client.get(url).body)
    @loaded = true
  end

end
