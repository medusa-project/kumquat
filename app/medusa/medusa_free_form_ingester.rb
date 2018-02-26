##
# Syncs items in collections that use the Free-Form package profile.
#
# Clients that don't want to concern themselves with package profiles can
# use MedusaIngester instead.
#
class MedusaFreeFormIngester < MedusaAbstractIngester

  @@logger = CustomLogger.instance

  ##
  # @param item_id [String]
  # @return [String]
  #
  def self.parent_id_from_medusa(item_id)
    parent_id = nil
    client = MedusaClient.new
    response = client.get_uuid(item_id)
    if response.status < 300
      json = response.body
      struct = JSON.parse(json)
      if struct['parent_directory']
        # Top-level items in a file group will have no parent_directory key,
        # so check one level up.
        json = client.get_uuid(struct['parent_directory']['uuid']).body
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
    check_collection(collection, PackageProfile::FREE_FORM_PROFILE)
    num_nodes = task ? count_tree_nodes(collection.effective_medusa_cfs_directory) : 0
    stats = { num_created: 0, num_skipped: 0, num_walked: 0 }
    ActiveRecord::Base.transaction do
      create_items_in_tree(collection, collection.effective_medusa_cfs_directory,
                           collection.effective_medusa_cfs_directory,
                           options.symbolize_keys, stats, task, num_nodes)
    end
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
    check_collection(collection, PackageProfile::FREE_FORM_PROFILE)

    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = items_in(collection.effective_medusa_cfs_directory)
    @@logger.debug("MedusaFreeFormIngester.delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    stats = { num_deleted: 0 }
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count

    ActiveRecord::Base.transaction do
      items.each_with_index do |item, index|
        unless medusa_items.include?(item.repository_id)
          @@logger.info("MedusaFreeFormIngester.delete_missing_items(): deleting "\
            "#{item.repository_id}")
          item.destroy!
          stats[:num_deleted] += 1
        end

        if task and index % 10 == 0
          task.update(percent_complete: index / num_items.to_f)
        end
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
  # @return [Hash<Symbol, Integer>] Hash with :num_created key referring to the
  #                                 total number of binaries in the collection.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  # @raises [IllegalContentError]
  #
  def recreate_binaries(collection, task = nil)
    check_collection(collection, PackageProfile::FREE_FORM_PROFILE)

    num_nodes = task ? count_tree_nodes(collection.effective_medusa_cfs_directory) : 0
    stats = { num_created: 0 }

    ActiveRecord::Base.transaction do
      recreate_binaries_in_tree(
          collection.effective_medusa_cfs_directory,
          collection.effective_medusa_cfs_directory, stats, task, num_nodes)

      # The binaries have been updated, but the image server may still have
      # cached versions of the old ones. Here, we will purge them.
      collection.items.each do |item|
        begin
          ImageServer.instance.purge_item_images_from_cache(item)
        rescue => e
          @@logger.error("MedusaFreeFormIngester.recreate_binaries(): failed to "\
              "purge item from image server cache: #{e}")
        end
      end
    end
    stats
  end

  private

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
        bs = file.to_binary(Binary::MasterType::ACCESS)
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
  # @return [Hash<Symbol, Integer>] Hash with :num_created key referring to the
  #                                 total number of binaries in the collection.
  #
  def recreate_binaries_in_tree(cfs_dir, top_cfs_dir, stats, task = nil,
                              num_nodes = 0, num_walked = 0)
    cfs_dir.directories.each do |dir|
      if task and num_walked % 10 == 0
        task.update(percent_complete: num_walked / num_nodes.to_f)
      end
      num_walked += 1
      recreate_binaries_in_tree(dir, top_cfs_dir, stats)
    end
    cfs_dir.files.each do |file|
      if task and num_walked % 10 == 0
        task.update(percent_complete: num_walked / num_nodes.to_f)
      end
      num_walked += 1
      item = Item.find_by_repository_id(file.uuid)
      if item
        @@logger.info("MedusaFreeFormIngester.recreate_binaries_in_tree(): "\
                            "updating binaries for item: #{file.uuid}")
        item.binaries.destroy_all
        bs = file.to_binary(Binary::MasterType::ACCESS)
        bs.item = item
        bs.save!
        stats[:num_created] += 1
      end
    end
  end

end
