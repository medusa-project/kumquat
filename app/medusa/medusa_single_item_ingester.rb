##
# Syncs items in collections that use the Single-Item Object package profile.
#
# Clients that don't want to concern themselves with package profiles can
# use MedusaIngester instead.
#
class MedusaSingleItemIngester < MedusaAbstractIngester

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
    check_collection(collection, PackageProfile::SINGLE_ITEM_OBJECT_PROFILE)

    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    status = { num_created: 0, num_skipped: 0 }
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
      item.binaries << file.to_binary(Binary::MasterType::PRESERVATION)

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
    check_collection(collection, PackageProfile::SINGLE_ITEM_OBJECT_PROFILE)

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
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>] Hash with :num_created key referring to the
  #                                 total number of binaries in the collection.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def update_binaries(collection, task = nil)
    check_collection(collection, PackageProfile::SINGLE_ITEM_OBJECT_PROFILE)

    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    stats = { num_created: 0 }
    files = pres_dir.files
    num_files = files.length
    files.each_with_index do |file, index|
      item = Item.find_by_repository_id(file.uuid)
      if item
        item.binaries.destroy_all

        # Create the preservation master binary.
        item.binaries << file.to_binary(Binary::MasterType::PRESERVATION)
        stats[:num_created] += 1

        # Find and create the access master binary.
        begin
          item.binaries << access_master_binary(cfs_dir, file)
          stats[:num_created] += 1
        rescue IllegalContentError => e
          @@logger.warn("MedusaSingleItemIngester.update_binaries(): #{e}")
        end

        item.save!
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
          return access_file.to_binary(Binary::MasterType::ACCESS)
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

end
