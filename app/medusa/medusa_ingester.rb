class MedusaIngester

  ##
  # Retrieves the current list of Medusa collections from the Medusa REST API
  # and creates or updates the local Collection counterpart instances.
  #
  # @param task [Task] Required for progress reporting
  # @return [void]
  #
  def ingest_collections(task = nil)
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
  # Retrieves the current contents of a collection's effective Medusa CFS
  # directory and creates or updates the items within according to the
  # collection's content profile.
  #
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @raises [ArgumentError] If the collection's file group or content profile
  #                         are not set.
  # @raises [IllegalContentError]
  #
  def ingest_items(collection, warnings = [])
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection content profile is not set' unless
        collection.content_profile

    ActiveRecord::Base.transaction do
      case collection.content_profile
        when ContentProfile::FREE_FORM_PROFILE
          ingest_free_form_items(collection)
        when ContentProfile::MAP_PROFILE
          ingest_map_items(collection, warnings)
      end
    end
  end

  private

  ##
  # @param collection [Collection]
  # @return [void]
  #
  def ingest_free_form_items(collection)
    # TODO: write this
  end

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [void]
  # @raises [IllegalContentError]
  #
  def ingest_map_items(collection, warnings = [])
    collection.effective_medusa_cfs_directory.directories.each do |top_item_dir|
      Rails.logger.info("ingest_map_items(): ingesting top-level item "\
      "#{top_item_dir.uuid}")

      item = Item.new(repository_id: top_item_dir.uuid,
                      collection_repository_id: collection.repository_id)
      if top_item_dir.directories.any?
        pres_dir = top_item_dir.directories.
            select{ |d| d.name == 'preservation' }.first
        if pres_dir
          # If the preservation directory contains more than one file, each
          # file corresponds to a child item with its own preservation master.
          if pres_dir.files.length > 1
            pres_dir.files.each do |pres_file|
              Rails.logger.info("ingest_map_items(): ingesting child item "\
              "#{pres_file.uuid}")
              child = Item.new(repository_id: pres_file.uuid,
                               collection_repository_id: collection.repository_id)
              child.parent_repository_id = item.repository_id

              # Create the preservation master bytestream.
              pres_file = pres_dir.files.first
              bs = child.bytestreams.build
              bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
              bs.repository_relative_pathname =
                  '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
              bs.media_type = pres_file.media_type

              # Find the access master bytestream.
              begin
                bs = map_access_master_bytestream(top_item_dir, pres_file)
                child.bytestreams << bs
              rescue IllegalContentError => e
                warnings << "#{e}"
              end

              child.save!
            end
          elsif pres_dir.files.length == 1
            # Create the preservation master bytestream.
            pres_file = pres_dir.files.first
            bs = item.bytestreams.build
            bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
            bs.repository_relative_pathname =
                '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
            bs.media_type = pres_file.media_type

            # Find the access master bytestream.
            begin
              bs = map_access_master_bytestream(top_item_dir, pres_file)
              item.bytestreams << bs
            rescue IllegalContentError => e
              warnings << "#{e}"
            end
          else
            msg = "Preservation directory #{pres_dir.uuid} is empty."
            Rails.logger.warn('ingest_map_items(): ' + msg)
            warnings << msg
          end
        else
          msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
          "directory."
          Rails.logger.warn('ingest_map_items(): ' + msg)
          warnings << msg
        end
      else
        msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
        raise IllegalContentError, msg
      end

      item.save!
    end
  end

  ##
  # @param item_cfs_dir [MedusaCfsDirectory]
  # @param pres_master_file [MedusaCfsFile]
  # @return [Bytestream]
  # @raises [IllegalContentError]
  #
  def map_access_master_bytestream(item_cfs_dir, pres_master_file)
    access_dir = item_cfs_dir.directories.
        select{ |d| d.name == 'access' }.first
    if access_dir
      if access_dir.files.any?
        pres_master_name = File.basename(pres_master_file.pathname)
        access_file = access_dir.files.
            select{ |f| f.name.chomp(File.extname(f.name)) ==
            pres_master_name.chomp(File.extname(pres_master_name)) }.first
        if access_file
          bs = Bytestream.new
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + access_file.repository_relative_pathname.reverse.chomp('/').reverse
          bs.media_type = access_file.media_type
          return bs
        else
          msg = "Preservation master file #{pres_master_file.uuid} has no "\
          "access master counterpart."
          Rails.logger.warn('map_access_master_bytestream(): ' + msg)
          raise IllegalContentError, msg
        end
      else
        msg = "Access master directory #{access_dir.uuid} has no files."
        Rails.logger.warn('map_access_master_bytestream(): ' + msg)
        raise IllegalContentError, msg
      end
    else
      msg = "Item directory #{item_cfs_dir.uuid} is missing an access "\
      "master subdirectory."
      Rails.logger.warn('map_access_master_bytestream(): ' + msg)
      raise IllegalContentError, msg
    end
  end

end
