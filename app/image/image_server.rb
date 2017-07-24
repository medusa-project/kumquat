class ImageServer

  include Singleton

  def client
    config = Configuration.instance
    HTTPClient.new do
      self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      self.force_basic_auth = true
      self.receive_timeout = 600
      uri = URI.parse(config.image_server_api_endpoint)
      domain = uri.scheme + '://' + uri.host
      user = config.image_server_api_user
      secret = config.image_server_api_secret
      self.set_auth(domain, user, secret)
    end
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
    identifier = item.iiif_image_binary&.iiif_image_identifier
    if identifier
      uri = Configuration.instance.image_server_api_endpoint +
          '/cache/' + CGI::escape(identifier)
      client.delete(uri)
    end
  end

end
