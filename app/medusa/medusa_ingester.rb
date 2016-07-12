class MedusaIngester

  class IngestMode
    # Creates new DLS items and updates existing DLS items.
    CREATE_AND_UPDATE = 'create_and_update'

    # Creates new DLS items but does not touch existing DLS items.
    CREATE_ONLY = 'create_only'

    # Deletes DLS items that have gone missing in Medusa, but does not create
    # or update anything.
    DELETE_MISSING = 'delete_missing'
  end

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
  # @param mode [String] One of the IngestMode constants.
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @raises [ArgumentError] If the collection's file group or content profile
  #                         are not set.
  # @raises [IllegalContentError]
  #
  def ingest_items(collection, mode, warnings = [])
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection content profile is not set' unless
        collection.content_profile

    ActiveRecord::Base.transaction do
      case collection.content_profile
        when ContentProfile::FREE_FORM_PROFILE
          ingest_free_form_items(collection, mode)
        when ContentProfile::MAP_PROFILE
          case mode
            when IngestMode::DELETE_MISSING
              delete_missing_map_items(collection)
            else
              ingest_map_items(collection, mode, warnings)
          end
      end
    end
  end

  private

  ##
  # @param collection [Collection]
  # @return [void]
  # @raises [IllegalContentError]
  #
  def delete_missing_map_items(collection)
    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_map_items = map_items_in(collection.effective_medusa_cfs_directory)
    Rails.logger.debug("delete_missing_map_items(): "\
        "#{medusa_map_items.length} items in CFS directory")

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    Item.where(collection_repository_id: collection.repository_id).each do |item|
      unless medusa_map_items.include?(item.repository_id)
        Rails.logger.info("delete_missing_map_items(): deleting "\
          "#{item.repository_id}")
        item.destroy!
      end
    end
  end

  ##
  # @param collection [Collection]
  # @param mode [String] One of the IngestMode constants.
  # @return [void]
  #
  def ingest_free_form_items(collection, mode)
    # TODO: write this
  end

  ##
  # @param collection [Collection]
  # @param mode [String] One of the IngestMode constants.
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [void]
  # @raises [IllegalContentError]
  #
  def ingest_map_items(collection, mode, warnings = [])
    collection.effective_medusa_cfs_directory.directories.each do |top_item_dir|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        if mode == IngestMode::CREATE_ONLY
          Rails.logger.info("ingest_map_items(): skipping item "\
              "#{top_item_dir.uuid}")
          next
        end
        Rails.logger.info("ingest_map_items(): updating item "\
                    "#{top_item_dir.uuid}")
      else
        Rails.logger.info("ingest_map_items(): creating item "\
                    "#{top_item_dir.uuid}")
        item = Item.new(repository_id: top_item_dir.uuid,
                        collection_repository_id: collection.repository_id)
      end
      if top_item_dir.directories.any?
        pres_dir = top_item_dir.directories.
            select{ |d| d.name == 'preservation' }.first
        if pres_dir
          # If the preservation directory contains more than one file, each
          # file corresponds to a child item with its own preservation master.
          if pres_dir.files.length > 1
            pres_dir.files.each do |pres_file|
              # Find or create the child item depending on the import mode and
              # whether it already exists.
              child = Item.find_by_repository_id(pres_file.uuid)
              if child
                if mode == IngestMode::CREATE_ONLY
                  Rails.logger.info("ingest_map_items(): skipping child item "\
                      "#{pres_file.uuid}")
                  next
                end
                Rails.logger.info("ingest_map_items(): updating child item "\
                    "#{pres_file.uuid}")
                # These will be recreated below.
                child.bytestreams.destroy_all
              else
                Rails.logger.info("ingest_map_items(): creating child item "\
                    "#{pres_file.uuid}")
                child = Item.new(repository_id: pres_file.uuid,
                                 collection_repository_id: collection.repository_id,
                                 parent_repository_id: item.repository_id)
              end

              # Create the preservation master bytestream.
              pres_file = pres_dir.files.first
              bs = child.bytestreams.build
              bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
              bs.repository_relative_pathname =
                  '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
              bs.media_type = pres_file.media_type

              # Find and create the access master bytestream.
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

            # Find and create the access master bytestream.
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

  ##
  # @return [Set<String>] Set of item UUIDs
  #
  def map_items_in(cfs_dir)
    medusa_item_uuids = Set.new
    cfs_dir.directories.each do |top_item_dir|
      medusa_item_uuids << top_item_dir.uuid
      if top_item_dir.directories.any?
        pres_dir = top_item_dir.directories.
            select{ |d| d.name == 'preservation' }.first
        if pres_dir
          # If the preservation directory contains more than one file, each
          # file corresponds to a child item with its own preservation master.
          if pres_dir.files.length > 1
            pres_dir.files.each { |file| medusa_item_uuids << file.uuid }
          end
        end
      end
    end
    medusa_item_uuids
  end

end
