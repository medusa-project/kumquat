class ImageServer

  include Singleton

  def client
    config = PearTree::Application.peartree_config
    HTTPClient.new do
      self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      self.force_basic_auth = true
      uri = URI.parse(config[:image_server_api_endpoint])
      domain = uri.scheme + '://' + uri.host
      user = config[:image_server_api_user]
      secret = config[:image_server_api_secret]
      self.set_auth(domain, user, secret)
    end
  end

  ##
  # @param item [Item]
  # @return [String, nil] Unencoded image server identifier of the item.
  #
  def identifier(item)
    item&.access_master_bytestream&.repository_relative_pathname&.reverse&.
        chomp('/')&.reverse
  end

  ##
  # Purges all content related to the given item from the image server cache
  # using the Cantaloupe API.
  #
  # @param item [Item]
  # @return [void]
  # @raises [Exception]
  #
  def purge_item_from_cache(item)
    identifier = identifier(item)
    if identifier
      uri = PearTree::Application.peartree_config[:image_server_api_endpoint] +
          '/' + CGI::escape(identifier)
      client.delete(uri)
    end
  end

end
