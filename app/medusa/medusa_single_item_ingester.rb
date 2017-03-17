##
# Syncs items in collections that use the Single-Item Object package profile.
#
# Clients that don't want to concern themselves with package profiles can
# use MedusaIngester instead.
#
class MedusaSingleItemIngester

  @@logger = CustomLogger.instance

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created and :num_skipped keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def create_items(collection, options = {}, task = nil)
    check_collection(collection)

    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    files = pres_dir.files
    num_files = files.length
    files.each_with_index do |file, index|
      # Find or create the child item.
      item = Item.find_by_repository_id(file.uuid)
      if item
        @@logger.info("MedusaSingleItemIngester.create_items(): skipping "\
          "item #{file.uuid}")
        status[:num_skipped] += 1
        next
      else
        @@logger.info("MedusaSingleItemIngester.create_items(): creating "\
          "item #{file.uuid}")
        item = Item.new(repository_id: file.uuid,
                        collection_repository_id: collection.repository_id)
        status[:num_created] += 1
      end

      # Create the preservation master binary.
      bs = item.binaries.build
      bs.cfs_file_uuid = file.uuid
      bs.binary_type = Binary::Type::PRESERVATION_MASTER
      bs.repository_relative_pathname =
          '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
      bs.media_type = file.media_type
      bs.read_size

      # Find and create the access master binary.
      begin
        item.binaries << access_master_binary(cfs_dir, file)
      rescue IllegalContentError => e
        @@logger.warn("MedusaSingleItemIngester.create_items(): #{e}")
      end

      item.update_from_embedded_metadata(options) if options[:extract_metadata]

      item.save!

      if task and index % 10 == 0
        task.update(percent_complete: index / num_files.to_f)
      end
    end
    status
  end

  ##
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_deleted key.
  # @raises [IllegalContentError]
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def delete_missing_items(collection, task = nil)
    check_collection(collection)

    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = items_in(collection.effective_medusa_cfs_directory)
    @@logger.debug("MedusaSingleItemIngester.delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    status = { num_deleted: 0 }
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count
    items.each_with_index do |item, index|
      unless medusa_items.include?(item.repository_id)
        @@logger.info("MedusaSingleItemIngester.delete_missing_items(): "\
          "deleting #{item.repository_id}")
        item.destroy!
        status[:num_deleted] += 1
      end

      if task and index % 10 == 0
        task.update(percent_complete: index / num_items.to_f)
      end
    end
    status
  end

  ##
  # @param collection [Collection]
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def replace_metadata(collection, task = nil)
    check_collection(collection)

    stats = { num_updated: 0 }
    items = collection.items
    num_items = items.count
    items.each_with_index do |item, index|
      @@logger.info("MedusaSingleItemIngester.replace_metadata(): "\
          "#{item.repository_id}")
      update_item_from_embedded_metadata(item)
      item.save!
      stats[:num_updated] += 1

      if task and index % 10 == 0
        task.update(percent_complete: index / num_items.to_f)
      end
    end
    stats
  end

  ##
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>]
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def update_binaries(collection, task = nil)
    check_collection(collection)

    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    stats = { num_updated: 0 }
    files = pres_dir.files
    num_files = files.length
    files.each_with_index do |file, index|
      item = Item.find_by_repository_id(file.uuid)
      if item
        item.binaries.destroy_all

        # Create the preservation master binary.
        bs = item.binaries.build
        bs.cfs_file_uuid = file.uuid
        bs.binary_type = Binary::Type::PRESERVATION_MASTER
        bs.repository_relative_pathname =
            '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
        bs.media_type = file.media_type
        bs.read_size
        bs.save!

        # Find and create the access master binary.
        begin
          bs = access_master_binary(cfs_dir, file)
          bs.item = item
          bs.save!
        rescue IllegalContentError => e
          @@logger.warn("MedusaSingleItemIngester.update_binaries(): #{e}")
        end

        stats[:num_updated] += 1
      end

      if task and index % 10 == 0
        task.update(percent_complete: index / num_files.to_f)
      end
    end

    # The binaries have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_from_cache(item)
      rescue => e
        @@logger.error("MedusaSingleItemIngester.update_binaries(): failed to "\
            "purge item from image server cache: #{e}")
      end
    end

    stats
  end

  private

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @param pres_master_file [MedusaCfsFile]
  # @return [Binary]
  # @raises [IllegalContentError]
  #
  def access_master_binary(cfs_dir, pres_master_file)
    access_dir = cfs_dir.directories.select{ |d| d.name == 'access' }.first
    if access_dir
      if access_dir.files.any?
        pres_master_name = File.basename(pres_master_file.pathname)
        access_file = access_dir.files.
            select{ |f| f.name.chomp(File.extname(f.name)) ==
            pres_master_name.chomp(File.extname(pres_master_name)) }.first
        if access_file
          return access_file.to_binary(Binary::Type::ACCESS_MASTER)
        else
          msg = "Preservation master file #{pres_master_file.uuid} has no "\
              "access master counterpart."
          @@logger.warn("MedusaSingleItemIngester.access_master_binary(): #{msg}")
          raise IllegalContentError, msg
        end
      else
        msg = "Access master directory #{access_dir.uuid} has no files."
        @@logger.warn("MedusaSingleItemIngester.access_master_binary(): #{msg}")
        raise IllegalContentError, msg
      end
    else
      msg = "Item directory #{cfs_dir.uuid} is missing an access master "\
          "subdirectory."
      @@logger.warn("MedusaSingleItemIngester.access_master_binary(): #{msg}")
      raise IllegalContentError, msg
    end
  end

  ##
  # @param collection [Collection]
  # @raises [ArgumentError]
  #
  def check_collection(collection)
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection package profile is set incorrectly' unless
        collection.package_profile == PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory
  end

  ##
  # @return [Set<String>] Set of all item UUIDs in a CFS directory using the
  #                       single-item object content profile.
  #
  def items_in(cfs_dir)
    medusa_item_uuids = Set.new
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first
    if pres_dir
      pres_dir.files.each { |file| medusa_item_uuids << file.uuid }
    end
    medusa_item_uuids
  end

  ##
  # Populates an item's metadata from its embedded binary metadata.
  #
  # @param item [Item]
  # @param options [Hash]
  # @option options [Boolean] :include_date_created
  #
  def update_item_from_embedded_metadata(item, options = {})
    initial_title = item.title
    item.update_from_embedded_metadata(options)
    # If there is no title present in the new metadata, restore the initial
    # title.
    if item.elements.select{ |e| e.name == 'title' }.empty?
      item.elements.build(name: 'title', value: initial_title)
    end
  end

end
