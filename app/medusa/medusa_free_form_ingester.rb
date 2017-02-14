##
# Syncs items in collections that use the Free-Form package profile.
#
# Clients that don't want to concern themselves with package profiles can
# use MedusaIngester instead.
#
class MedusaFreeFormIngester

  @@logger = CustomLogger.instance

  ##
  # Creates new DLS items for any Medusa items that do not already exist in
  # the DLS.
  #
  # @param collection [Collection]
  # @param options [Hash] Options hash.
  # @option options [Boolean] :extract_metadata
  # @option options [Boolean] :include_date_created
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_skipped,
  #                                and :num_walked keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  # @raises [IllegalContentError]
  #
  def create_items(collection, options = {}, task = nil)
    check_collection(collection)
    num_nodes = task ? count_tree_nodes(collection.effective_medusa_cfs_directory) : 0
    status = { num_created: 0, num_skipped: 0, num_walked: 0 }
    create_items_in_tree(collection, collection.effective_medusa_cfs_directory,
                         collection.effective_medusa_cfs_directory,
                         options.symbolize_keys, status, task, num_nodes)
  end

  ##
  # Deletes DLS items that are no longer present in Medusa.
  #
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
    @@logger.debug("MedusaFreeFormIngester.delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    medusa_items = items_in(collection.effective_medusa_cfs_directory)

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    status = { num_deleted: 0 }
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count
    items.each_with_index do |item, index|
      unless medusa_items.include?(item.repository_id)
        @@logger.info("MedusaFreeFormIngester.delete_missing_items(): deleting "\
          "#{item.repository_id}")
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
  # Replaces existing DLS metadata for all items in the given collection with
  # metadata drawn from embedded file metadata, such as IPTC.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def replace_metadata(collection, task = nil)
    check_collection(collection)

    stats = { num_updated: 0 }
    # Iterate only file-variant items, as they are the only ones with embedded
    # metadata.
    items = collection.items.where(variant: Item::Variants::FILE)
    num_items = items.count
    items.each_with_index do |item, index|
      @@logger.info("MedusaFreeFormIngester.replace_metadata(): #{item.repository_id}")
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
  # Updates the binaries attached to each item in the given collection based on
  # the contents of the items in Medusa.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  # @raises [IllegalContentError]
  #
  def update_binaries(collection, task = nil)
    check_collection(collection)

    num_nodes = task ? count_tree_nodes(collection.effective_medusa_cfs_directory) : 0
    stats = { num_updated: 0 }
    update_binaries_in_tree(
        collection.effective_medusa_cfs_directory,
        collection.effective_medusa_cfs_directory, stats, task, num_nodes)

    # The binaries have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_from_cache(item)
      rescue => e
        @@logger.error("MedusaFreeFormIngester.update_binaries(): failed to "\
            "purge item from image server cache: #{e}")
      end
    end
    stats
  end

  private

  ##
  # @param collection [Collection]
  # @raises [ArgumentError]
  #
  def check_collection(collection)
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory
  end

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @param count [Integer] For internal use.
  # @return [Integer]
  #
  def count_tree_nodes(cfs_dir, count = 0)
    cfs_dir.directories.each do |dir|
      count += 1
      count = count_tree_nodes(dir, count)
    end
    count += cfs_dir.files.length
    count
  end

  ##
  # @param collection [Collection]
  # @param cfs_dir [MedusaCfsDirectory]
  # @param top_cfs_dir [MedusaCfsDirectory]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @option options [Boolean] :include_date_created
  # @param status [Hash]
  # @param task [Task] Supply to receive status updates.
  # @param num_nodes [Integer]
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_skipped, and
  #                                :num_walked keys.
  #
  def create_items_in_tree(collection, cfs_dir, top_cfs_dir, options, status,
                           task = nil, num_nodes = 0)
    cfs_dir.directories.each do |dir|
      item = Item.find_by_repository_id(dir.uuid)
      if item
        @@logger.info("MedusaFreeFormIngester.create_items_in_tree(): "\
              "skipping item #{dir.uuid}")
        status[:num_skipped] += 1
      else
        @@logger.info("MedusaFreeFormIngester.create_items_in_tree(): "\
              "creating item #{dir.uuid}")
        item = Item.new(repository_id: dir.uuid,
                        parent_repository_id: (cfs_dir.uuid != top_cfs_dir.uuid) ? cfs_dir.uuid : nil,
                        collection_repository_id: collection.repository_id,
                        variant: Item::Variants::DIRECTORY)
        # Assign a title of the directory name.
        item.elements.build(name: 'title', value: dir.name)
        item.save!
        status[:num_created] += 1
      end

      if task
        task.update(percent_complete: status[:num_walked] / num_nodes.to_f)
      end

      status[:num_walked] += 1
      create_items_in_tree(collection, dir, top_cfs_dir, options, status,
                           task, num_nodes)
    end
    cfs_dir.files.each do |file|
      item = Item.find_by_repository_id(file.uuid)
      if item
        @@logger.info("MedusaFreeFormIngester.create_items_in_tree(): "\
                "skipping item #{file.uuid}")
        status[:num_skipped] += 1
        next
      else
        @@logger.info("MedusaFreeFormIngester.create_items_in_tree(): "\
                "creating item #{file.uuid}")
        item = Item.new(repository_id: file.uuid,
                        parent_repository_id: (cfs_dir.uuid != top_cfs_dir.uuid) ? cfs_dir.uuid : nil,
                        collection_repository_id: collection.repository_id,
                        variant: Item::Variants::FILE)
        item.elements.build(name: 'title', value: file.name)

        # Create its corresponding binary.
        bs = file.to_binary(Binary::Type::ACCESS_MASTER)
        bs.item = item
        bs.save!

        update_item_from_embedded_metadata(item, options) if
            options[:extract_metadata]

        item.save!
        status[:num_created] += 1
      end

      if task
        task.update(percent_complete: status[:num_walked] / num_nodes.to_f)
      end
      status[:num_walked] += 1
    end
    status
  end

  ##
  # Populates the given set with Medusa file/directory UUIDs corresponding to
  # items.
  #
  # @param cfs_dir [MedusaCfsDirectory]
  # @param medusa_item_uuids [Set<String>]
  # @return [void]
  #
  def item_uuids_in_tree(cfs_dir, medusa_item_uuids)
    cfs_dir.directories.each do |dir|
      medusa_item_uuids << dir.uuid
      item_uuids_in_tree(dir, medusa_item_uuids)
    end
    cfs_dir.files.each do |file|
      medusa_item_uuids << file.uuid
    end
  end

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @return [Set<String>] Set of item UUIDs
  #
  def items_in(cfs_dir)
    medusa_item_uuids = Set.new
    item_uuids_in_tree(cfs_dir, medusa_item_uuids)
    medusa_item_uuids
  end

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @param top_cfs_dir [MedusaCfsDirectory]
  # @param stats [Hash<Symbol,Integer>]
  # @param task [Task] Supply to receive progress updates.
  # @param num_nodes [Integer]
  # @param num_walked [Integer] For internal use.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_binaries_in_tree(cfs_dir, top_cfs_dir, stats, task = nil,
                              num_nodes = 0, num_walked = 0)
    cfs_dir.directories.each do |dir|
      if task and num_walked % 10 == 0
        task.update(percent_complete: num_walked / num_nodes.to_f)
      end
      num_walked += 1
      update_binaries_in_tree(dir, top_cfs_dir, stats)
    end
    cfs_dir.files.each do |file|
      if task and num_walked % 10 == 0
        task.update(percent_complete: num_walked / num_nodes.to_f)
      end
      num_walked += 1
      item = Item.find_by_repository_id(file.uuid)
      if item
        @@logger.info("MedusaFreeFormIngester.update_binaries_in_tree(): "\
                            "updating binaries for item: #{file.uuid}")
        item.binaries.destroy_all
        bs = file.to_binary(Binary::Type::ACCESS_MASTER)
        bs.item = item
        bs.save!
        stats[:num_updated] += 1
      end
    end
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
