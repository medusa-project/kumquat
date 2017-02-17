class MedusaClient

  ##
  # @param uuid [String]
  # @return [Class]
  #
  def class_of_uuid(uuid)
    url = Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
        uuid.to_s.strip + '.json'
    begin
    response = Medusa.client.get(url, follow_redirect: false)
    location = response.header['location'].first
    if location.include?('/bit_level_file_groups/')
      return MedusaFileGroup
    elsif location.include?('/cfs_directories/')
      return MedusaCfsDirectory
    elsif location.include?('/cfs_files/')
      return MedusaCfsFile
    end
    rescue HTTPClient::BadResponseError
      # no-op
    end
    nil
  end

end