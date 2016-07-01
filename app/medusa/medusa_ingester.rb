class MedusaIngester

  ##
  # @param task [Task] Required for progress reporting
  # @return [void]
  #
  def inget_collections(task = nil)
    config = PearTree::Application.peartree_config
    url = sprintf('%s/collections.json', config[:medusa_url].chomp('/'))
    response = Medusa.client.get(url, follow_redirect: true)
    struct = JSON.parse(response.body)
    struct.each_with_index do |st, index|
      col = Collection.find_or_create_by(repository_id: st['uuid'])
      col.update_from_medusa
      col.save!

      if task and index % 10 == 0
        task.percent_complete = index / struct.length.to_f
        task.save
      end
    end
  end

  ##
  # @param collection [Collection]
  #
  def ingest_items(collection)

  end

  ##
  # Queries Medusa to find all bytestreams for the Item with the given ID.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If the item ID is nil
  #
  def bytestreams_for(item_id)
    raise ArgumentError, 'No ID provided.' unless item_id
    case self.id
      when 0
        return free_form_bytestreams_for(item_id)
      when 1
        return map_bytestreams_for(item_id)
    end
    []
  end

  ##
  # Queries Medusa to find the parent ID of the Item with the given ID.
  #
  # @param item_id [String]
  # @param content_profile [ContentProfile]
  # @return [String, nil] UUID of the parent item of the given item, or nil if
  #                       there is no parent.
  # @raises [HTTPClient::BadResponseError]
  # @raises [ArgumentError] If any arguments are nil
  #
  def parent_id_of(item_id, content_profile)
    raise ArgumentError, 'No ID provided.' unless item_id
    raise ArgumentError, 'No content profile provided.' unless content_profile
    case content_profile.id
      when 0
        return free_form_parent_id_of(item_id)
      when 1
        return map_parent_id_of(item_id)
    end
    nil
  end

  private

  ##
  # In the free-form profile, there is one bytestream per file. Directories
  # have no bytestreams.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  #
  def free_form_bytestreams_for(item_id)
    bytestreams = []
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['mtime'] # Only files will have this key.
        bs = Bytestream.new
        bs.repository_relative_pathname =
            '/' + struct['relative_pathname'].reverse.chomp('/').reverse
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.infer_media_type
        bytestreams << bs
      end
    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def free_form_parent_id_of(item_id)
    parent_id = nil
    client = Medusa.client
    response = client.get(medusa_url(item_id), follow_redirect: true)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['parent_directory']
        # Top-level items in a file group will have no parent_directory key,
        # so check one level up.
        json = client.get(medusa_url(struct['parent_directory']['uuid']),
                          follow_redirect: true).body
        struct2 = JSON.parse(json)
        if struct2['parent_directory']
          parent_id = struct['parent_directory']['uuid']
        end
      elsif struct['directory']
        parent_id = struct['directory']['uuid']
      end
    end
    parent_id
  end

  ##
  # Child items will reside in a directory called `access` or
  # `preservation`. These are the only items in this profile that will have
  # any associated bytestreams. Preservation and access filenames will be the
  # same, except preservation files will end in .tif and access filenames in
  # .jp2.
  #
  # @param item_id [String]
  # @return [Array<Bytestream>]
  #
  def map_bytestreams_for(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)
    bytestreams = []

    if struct['directory']
      case struct['directory']['name']
        when 'preservation'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bytestreams << access_master_counterpart(bs)
        when 'access'
          # add the preservation master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse.
                  gsub('/preservation/', '/access/').chomp('.jp2') + '.tif'
          bs.infer_media_type
          bytestreams << bs

          # add the access master
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + struct['relative_pathname'].reverse.chomp('/').reverse
          bs.infer_media_type
          bytestreams << bs
      end

    end
    bytestreams
  end

  ##
  # @param item_id [String]
  # @return [String]
  #
  def map_parent_id_of(item_id)
    client = Medusa.client
    json = client.get(medusa_url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)

    # Top-level items will have `access`, `metadata`, and/or `preservation`
    # subdirectories.
    if struct['subdirectories']&.
        select{ |n| %w(access metadata preservation).include?(n['name']) }&.any?
      return nil
      # Child items will reside in a directory called `access` or
      # `preservation`.
    elsif struct['directory'] and
        %w(access preservation).include?(struct['directory']['name'])
      json = client.get(medusa_url(struct['directory']['uuid']),
                        follow_redirect: true).body
      struct2 = JSON.parse(json)
      return struct2['parent_directory']['uuid']
    end
  end

end
