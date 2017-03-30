class Medusa

  ##
  # @param uuid [String]
  # @return [String, nil] URI of the corresponding Medusa resource.
  #
  def self.url(uuid)
    sprintf('%s/uuids/%s.json', Configuration.instance.medusa_url.chomp('/'),
            uuid)
  end

end
