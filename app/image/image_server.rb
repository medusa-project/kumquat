class ImageServer

  include Singleton

  ##
  # @param binary [Binary]
  # @param region [String,Symbol]
  # @param size [String,Integer]
  # @param rotation [Integer]
  # @param color [String]
  # @param content_disposition [String] Cantaloupe-specific argument.
  # @param filename [String]            Cantaloupe-specific argument.
  # @param cache [Boolean]              Cantaloupe-specific argument.
  # @return [String, nil]               Image URL, or nil if the binary is not
  #                                     compatible with the image server or
  #                                     safe for it to serve.
  #
  def self.binary_image_v2_url(binary:,
                               region:              'full',
                               size:                'max',
                               rotation:            0,
                               color:               'default',
                               format:              'jpg',
                               content_disposition: nil,
                               filename:            nil,
                               cache:               true)
    return nil unless binary.image_server_safe?
    query  = {}
    region = region.to_s
    size   = "!#{size},#{size}" if size.to_i == size
    url    = sprintf('%s/%s/%s/%d/%s.%s',
                     binary.iiif_image_v2_url,
                     region, size, rotation, color, format)
    if binary.duration
      # ?time=hh:mm:ss is a nonstandard argument supported only by
      # Cantaloupe's FfmpegProcessor. All other processors will ignore it.
      # If it's missing, the first frame will be returned.
      #
      # For videos of all lengths, the time needs to be enough to advance
      # past title frames but not longer than the duration. It would be
      # easier to hard-code something like 00:00:10, but there are actually
      # some videos in the repository that are two seconds long.
      # FfmpegProcessor doesn't allow a percentage argument because ffprobe
      # doesn't. (DLD-102)
      #
      # Ideally we would use ffmpeg's scene detection, but FfmpegProcessor
      # doesn't support that yet.
      # TODO: use meta-identifier suffix
      query['time'] = TimeUtils.seconds_to_hms(binary.duration * 0.2)
    end
    query = image_v2_url_query(query:               query,
                               format:              format,
                               content_disposition: content_disposition,
                               filename:            filename,
                               cache:               cache)
    url += '?' + query.to_query if query.keys.any?
    url
  end

  ##
  # @param file [Medusa::File]
  # @param region [String,Symbol]
  # @param size [String,Integer]
  # @param rotation [Integer]
  # @param color [String]
  # @param content_disposition [String] Cantaloupe-specific argument.
  # @param filename [String]            Cantaloupe-specific argument.
  # @param cache [Boolean]              Cantaloupe-specific argument.
  # @return [String, nil]               Image URL, or nil if the binary is not
  #                                     compatible with the image server or
  #                                     safe for it to serve.
  #
  def self.file_image_v2_url(file:,
                             region:              'full',
                             size:                'max',
                             rotation:            0,
                             color:               'default',
                             format:              'jpg',
                             content_disposition: nil,
                             filename:            nil,
                             cache:               true)
    query    = {}
    region   = region.to_s
    size     = "!#{size},#{size}" if size.to_i == size
    base_url = Configuration.instance.iiif_image_v2_url + '/' + file.uuid
    url      = sprintf('%s/%s/%s/%d/%s.%s',
                       base_url, region, size, rotation, color, format)
    query    = image_v2_url_query(query:               query,
                                  format:              format,
                                  content_disposition: content_disposition,
                                  filename:            filename,
                                  cache:               cache)
    url += '?' + query.to_query if query.keys.any?
    url
  end

  ##
  # Private method.
  #
  # @param query [Hash]                 Existing query keys and values.
  # @param content_disposition [String] Cantaloupe-specific argument.
  # @param filename [String]            Cantaloupe-specific argument.
  # @param cache [Boolean]              Cantaloupe-specific argument.
  # @return [Hash]                      URL query.
  #
  def self.image_v2_url_query(query:               {},
                              format:              'jpg',
                              content_disposition: nil,
                              filename:            nil,
                              cache:               true)
    if content_disposition
      if content_disposition == 'attachment'
        if filename.blank?
          filename = File.basename(file.filename, File.extname(file.filename)) +
            '.' + format
        end
        value = "attachment; filename=\"#{filename}\""
      else
        value = content_disposition
      end
      query['response-content-disposition'] = value
    end
    query['cache'] = 'false' unless cache
    query
  end

  def client
    config = Configuration.instance
    HTTPClient.new do
      # use the OS cert store
      self.ssl_config.cert_store.set_default_paths
      #self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      self.force_basic_auth = true
      self.receive_timeout = 600
      uri     = URI.parse(config.image_server_api_endpoint)
      domain  = uri.scheme + '://' + uri.host
      domain += ":#{uri.port}" unless [80, 443].include?(uri.port)
      user    = config.image_server_api_user
      secret  = config.image_server_api_secret
      self.set_auth(domain, user, secret)
    end
  end

  ##
  # Purges all items from the image server cache using the Cantaloupe API.
  #
  # @return [void]
  # @raises [IOError]
  #
  def purge_all_images_from_cache
    uri = Configuration.instance.image_server_api_endpoint + '/tasks'
    headers = {
        'Content-Type': 'application/json'
    }
    body = JSON.generate({ verb: 'PurgeCache' })

    response = client.post(uri, body, headers)
    if response.status > 204
      raise IOError, "Unexpected response from image server: #{response.status}"
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
  # @raises [IOError]
  #
  def purge_item_images_from_cache(item)
    identifier = item.effective_image_binary&.iiif_image_identifier
    if identifier
      uri = Configuration.instance.image_server_api_endpoint + '/tasks'
      headers = {
          'Content-Type': 'application/json'
      }
      body = JSON.generate({
          verb: 'PurgeItemFromCache',
          identifier: identifier
      })

      response = client.post(uri, body, headers)
      if response.status > 204
        raise IOError, "Unexpected response from image server: #{response.status}"
      end
    end
  end

end
