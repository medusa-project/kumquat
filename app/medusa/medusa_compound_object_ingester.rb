##
# Syncs items in collections that use the Compound Object package profile.
#
# The compound object profile looks like:
# * item_dir
#     * access
#         * page1.jp2
#         * page2.jp2
#     * preservation
#         * page1.tif
#         * page2.tif
#     * supplementary (optional)
#         * file (0-*)
#     * composite
#         * file (0-*)
#
# Clients that don't want to concern themselves with package profiles can
# use MedusaIngester instead.
#
class MedusaCompoundObjectIngester

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
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated,
  #                                :num_deleted, and/or :num_skipped keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  # @raises [IllegalContentError]
  #
  def create_items(collection, options = {}, task = nil)
    check_collection(collection)
    options = options.symbolize_keys

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
            "skipping item #{top_item_dir.uuid}")
        status[:num_skipped] += 1
      else
        @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
            "creating item #{top_item_dir.uuid}")
        item = Item.new(repository_id: top_item_dir.uuid,
                        collection_repository_id: collection.repository_id)
        # Assign a title of the directory name.
        item.elements.build(name: 'title', value: top_item_dir.name)
        status[:num_created] += 1
      end
      if top_item_dir.directories.any?
        pres_dir = top_item_dir.directories.
            select{ |d| d.name == 'preservation' }.first
        if pres_dir
          # If the preservation directory contains more than one file, each
          # file corresponds to a child item with its own preservation master.
          if pres_dir.files.length > 1
            pres_dir.files.each do |pres_file|
              # Find or create the child item.
              child = Item.find_by_repository_id(pres_file.uuid)
              if child
                @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "skipping child item #{pres_file.uuid}")
                status[:num_skipped] += 1
              else
                @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "creating child item #{pres_file.uuid}")
                child = Item.new(repository_id: pres_file.uuid,
                                 collection_repository_id: collection.repository_id,
                                 parent_repository_id: item.repository_id)
                # Assign a title of the filename.
                child.elements.build(name: 'title', value: pres_file.name)
                status[:num_created] += 1
              end

              # Create the preservation master binary.
              child.binaries << pres_file.
                  to_binary(Binary::Type::PRESERVATION_MASTER)

              # Set the child's variant.
              basename = File.basename(pres_file.repository_relative_pathname)
              if basename.include?('_frontmatter')
                child.variant = Item::Variants::FRONT_MATTER
              elsif basename.include?('_index')
                child.variant = Item::Variants::INDEX
              elsif basename.include?('_key')
                child.variant = Item::Variants::KEY
              elsif basename.include?('_title')
                child.variant = Item::Variants::TITLE
              else
                child.variant = Item::Variants::PAGE
              end

              # Find and create the access master binary.
              begin
                child.binaries << access_master_binary(top_item_dir, pres_file)
              rescue IllegalContentError => e
                @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{e}")
              end

              child.update_from_embedded_metadata(options) if
                  options[:extract_metadata]

              child.save!
            end
          elsif pres_dir.files.length == 1
            # Create the preservation master binary.
            pres_file = pres_dir.files.first
            item.binaries << pres_file.
                to_binary(Binary::Type::PRESERVATION_MASTER)

            # Find and create the access master binary.
            begin
              item.binaries << access_master_binary(top_item_dir, pres_file)
            rescue IllegalContentError => e
              @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{e}")
            end

            item.update_from_embedded_metadata(options) if
                options[:extract_metadata]
          else
            msg = "Preservation directory #{pres_dir.uuid} is empty."
            @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{msg}")
          end
        else
          msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
              "directory."
          @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{msg}")
        end

        supplementary_dir = top_item_dir.directories.
            select{ |d| d.name == 'supplementary' }.first
        if supplementary_dir
          supplementary_dir.files.each do |supp_file|
            # Find or create the supplementary item.
            child = Item.find_by_repository_id(supp_file.uuid)
            if child
              @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "skipping supplementary item #{supp_file.uuid}")
              status[:num_skipped] += 1
            else
              @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "creating supplementary item #{supp_file.uuid}")
              child = Item.new(repository_id: supp_file.uuid,
                               collection_repository_id: collection.repository_id,
                               parent_repository_id: item.repository_id,
                               variant: Item::Variants::SUPPLEMENT)
              # Assign a title of the filename.
              child.elements.build(name: 'title', value: supp_file.name)
              child.binaries << supp_file.to_binary(Binary::Type::PRESERVATION_MASTER)
              child.save!
              status[:num_created] += 1
            end
          end
        end

        composite_dir = top_item_dir.directories.
            select{ |d| d.name == 'composite' }.first
        if composite_dir
          composite_dir.files.each do |comp_file|
            # Find or create the composite item.
            child = Item.find_by_repository_id(comp_file.uuid)
            if child
              @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "skipping composite item #{comp_file.uuid}")
              status[:num_skipped] += 1
            else
              @@logger.info("MedusaCompoundObjectIngester.create_items(): "\
                    "creating composite item #{comp_file.uuid}")
              child = Item.new(repository_id: comp_file.uuid,
                               collection_repository_id: collection.repository_id,
                               parent_repository_id: item.repository_id,
                               variant: Item::Variants::COMPOSITE)
              # Assign a title of the filename.
              child.elements.build(name: 'title', value: comp_file.name)
              child.binaries << comp_file.to_binary(Binary::Type::PRESERVATION_MASTER)
              child.save!
              status[:num_created] += 1
            end
          end
        end
      else
        msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
        @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{msg}")
      end

      item.save!

      task.update(percent_complete: index / num_directories.to_f) if task
    end
    status
  end

  ##
  # Deletes DLS items that are no longer present in Medusa.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_deleted key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  # @raises [IllegalContentError]
  #
  def delete_missing_items(collection, task = nil)
    check_collection(collection)

    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = items_in(collection.effective_medusa_cfs_directory)
    @@logger.debug("MedusaCompoundObjectIngester.delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    status = { num_deleted: 0 }
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count
    items.each_with_index do |item, index|
      unless medusa_items.include?(item.repository_id)
        @@logger.info("MedusaCompoundObjectIngester.delete_missing_items(): "\
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
  # Replaces existing DLS metadata for all items in the given collection with
  # metadata drawn from embedded file metadata, such as IPTC.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  #
  def replace_metadata(collection, task = nil)
    check_collection(collection)

    stats = { num_updated: 0 }
    items = collection.items
    num_items = items.count
    items.each_with_index do |item, index|
      @@logger.info("MedusaCompoundObjectIngester.replace_metadata(): #{item.repository_id}")
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
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>]
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  #
  def update_binaries(collection, task = nil)
    check_collection(collection)

    stats = { num_updated: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    collection.items.each { |item| item.binaries.destroy_all }

    directories.each_with_index do |top_item_dir, index|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        item.binaries.destroy_all

        if top_item_dir.directories.any?
          pres_dir = top_item_dir.directories.
              select{ |d| d.name == 'preservation' }.first
          if pres_dir
            # If the preservation directory contains more than one file, each
            # file corresponds to a child item with its own preservation master.
            if pres_dir.files.length > 1
              pres_dir.files.each do |pres_file|
                # Find the child item.
                child = Item.find_by_repository_id(pres_file.uuid)
                if child
                  @@logger.info("MedusaCompoundObjectIngester.update_binaries(): "\
                      "updating child item #{pres_file.uuid}")

                  child.binaries.destroy_all

                  # Create the preservation master binary.
                  bs = pres_file.to_binary(Binary::Type::PRESERVATION_MASTER)
                  bs.item = child
                  bs.save!

                  # Find and create the access master binary.
                  begin
                    bs = access_master_binary(top_item_dir, pres_file)
                    bs.item = child
                    bs.save!
                  rescue IllegalContentError => e
                    @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{e}")
                  end
                  stats[:num_updated] += 1
                else
                  @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): "\
                      "skipping child item #{pres_file.uuid} (no item)")
                end
              end
            elsif pres_dir.files.length == 1
              @@logger.info("MedusaCompoundObjectIngester.update_binaries(): "\
                    "updating item #{item.repository_id}")

              item.binaries.destroy_all

              # Create the preservation master binary.
              pres_file = pres_dir.files.first
              item.binaries <<
                  pres_file.to_binary(Binary::Type::PRESERVATION_MASTER)

              # Find and create the access master binary.
              begin
                item.binaries << access_master_binary(top_item_dir, pres_file)
              rescue IllegalContentError => e
                @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{e}")
              end

              item.save!

              stats[:num_updated] += 1
            else
              msg = "Preservation directory #{pres_dir.uuid} is empty."
              @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
            end
          else
            msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
                "directory."
            @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
          end

          # Update supplementary item binaries.
          supplementary_dir = top_item_dir.directories.
              select{ |d| d.name == 'supplementary' }.first
          if supplementary_dir
            supplementary_dir.files.each do |supp_file|
              item = Item.find_by_repository_id(supp_file.uuid)
              if item
                item.binaries.destroy_all
                item.binaries << supp_file.to_binary(Binary::Type::PRESERVATION_MASTER)
                item.save!
                stats[:num_updated] += 1
              else
                msg = "Supplementary file #{supp_file.uuid} is missing an "\
                    "item counterpart."
                @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
              end
            end
          end

          # Update compoosite item binaries.
          composite_dir = top_item_dir.directories.
              select{ |d| d.name == 'composite' }.first
          if composite_dir
            composite_dir.files.each do |comp_file|
              item = Item.find_by_repository_id(comp_file.uuid)
              if item
                item.binaries.destroy_all
                item.binaries << comp_file.to_binary(Binary::Type::PRESERVATION_MASTER)
                item.save!
                stats[:num_updated] += 1
              else
                msg = "Composite file #{comp_file.uuid} is missing an "\
                    "item counterpart."
                @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
              end
            end
          end
        else
          msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
          @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
        end
      else
        msg = "No item for directory: #{top_item_dir.uuid}"
        @@logger.warn("MedusaCompoundObjectIngester.update_binaries(): #{msg}")
      end
      task.update(percent_complete: index / num_directories.to_f) if task
    end

    # The binaries have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_from_cache(item)
      rescue => e
        @@logger.error("MedusaCompoundObjectIngester.update_binaries(): "\
            "failed to purge item from image server cache: #{e}")
      end
    end
    stats
  end

  private

  ##
  # @param item_cfs_dir [MedusaCfsDirectory]
  # @param pres_master_file [MedusaCfsFile]
  # @return [Binary]
  # @raises [IllegalContentError]
  #
  def access_master_binary(item_cfs_dir, pres_master_file)
    access_dir = item_cfs_dir.directories.
        select{ |d| d.name == 'access' }.first
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
          @@logger.warn("MedusaCompoundObjectIngester.access_master_binary(): #{msg}")
          raise IllegalContentError, msg
        end
      else
        msg = "Access master directory #{access_dir.uuid} has no files."
        @@logger.warn("MedusaCompoundObjectIngester.access_master_binary(): #{msg}")
        raise IllegalContentError, msg
      end
    else
      msg = "Item directory #{item_cfs_dir.uuid} is missing an access "\
          "master subdirectory."
      @@logger.warn("MedusaCompoundObjectIngester.access_master_binary(): #{msg}")
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
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory
  end

  ##
  # @return [Set<String>] Set of all item UUIDs in a CFS directory using the
  #                       compound object content profile.
  #
  def items_in(cfs_dir)
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
