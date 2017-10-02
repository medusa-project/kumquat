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
  # @param collection [Collection]
  # @param task [Task] Optional Task for monitoring progress.
  # @return [void]
  #
  def purge_collection_item_images_from_cache(collection, task = nil)
    Item.uncached do
      items = Item.where(collection_repository_id: collection.repository_id)
      count = items.count
      items.find_each.with_index do |item, index|
        purge_item_images_from_cache(item)
        if task and index % 10 == 0
          task.progress = index / count.to_f
        end
      end
    end

    task&.succeeded
  end

  ##
  # Purges all content related to the given item from the image server cache
  # using the Cantaloupe API.
  #
  # @param item [Item]
  # @return [void]
  # @raises [Exception]
  #
  def purge_item_images_from_cache(item)
    identifier = item.iiif_image_binary&.iiif_image_identifier
    if identifier
      uri = Configuration.instance.image_server_api_endpoint +
          '/cache/' + CGI::escape(identifier)
      client.delete(uri)
    end
  end

end
