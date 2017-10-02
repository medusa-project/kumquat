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
class MedusaCompoundObjectIngester < MedusaAbstractIngester

  @@logger = CustomLogger.instance

  ##
  # @param item_id [String]
  # @return [String]
  #
  def self.parent_id_from_medusa(item_id)
    client = MedusaClient.new
    json = client.get_uuid(item_id).body
    struct = JSON.parse(json)

    # Child items will reside in a directory called `access` or
    # `preservation`.
    if struct['directory'] and
        %w(access preservation).include?(struct['directory']['name'])
      json = client.get_uuid(struct['directory']['uuid']).body
      struct2 = JSON.parse(json)
      return struct2['parent_directory']['uuid']
    end
    nil
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
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated,
  #                                and :num_skipped keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  # @raises [IllegalContentError]
  #
  def create_items(collection, options = {}, task = nil)
    check_collection(collection, PackageProfile::COMPOUND_OBJECT_PROFILE)
    options = options.symbolize_keys

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
      object_exists = false
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        object_exists = true
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
      # Whether or not the object already exists, scan the filesystem for new
      # child items to add.
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

                # Set the variant.
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

                # Create the preservation master binary.
                child.binaries << pres_file.
                    to_binary(Binary::MasterType::PRESERVATION)

                # Find and create the access master binary.
                begin
                  child.binaries << access_master_binary(top_item_dir, pres_file)
                rescue IllegalContentError => e
                  @@logger.warn("MedusaCompoundObjectIngester.create_items(): #{e}")
                end

                child.update_from_embedded_metadata(options) if
                    options[:extract_metadata]

                child.save!

                status[:num_created] += 1
              end
            end
          elsif pres_dir.files.length == 1 and !object_exists
            # Create the preservation master binary.
            pres_file = pres_dir.files.first
            item.binaries << pres_file.
                to_binary(Binary::MasterType::PRESERVATION)

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
              child.binaries << supp_file.to_binary(Binary::MasterType::PRESERVATION)
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
              child.binaries << comp_file.to_binary(Binary::MasterType::PRESERVATION)
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
    check_collection(collection, PackageProfile::COMPOUND_OBJECT_PROFILE)

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
  # Updates the binaries attached to each item in the given collection based on
  # the contents of the items in Medusa.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>] Hash with :num_created key referring to the
  #                                 total number of binaries in the collection.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  #
  def recreate_binaries(collection, task = nil)
    check_collection(collection, PackageProfile::COMPOUND_OBJECT_PROFILE)

    stats = { num_created: 0 }
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
                  @@logger.info("MedusaCompoundObjectIngester.recreate_binaries(): "\
                      "updating child item #{pres_file.uuid}")

                  child.binaries.destroy_all

                  # Create the preservation master binary.
                  bs = pres_file.to_binary(Binary::MasterType::PRESERVATION)
                  bs.item = child
                  bs.save!
                  stats[:num_created] += 1

                  # Find and create the access master binary.
                  begin
                    bs = access_master_binary(top_item_dir, pres_file)
                    bs.item = child
                    bs.save!
                    stats[:num_created] += 1
                  rescue IllegalContentError => e
                    @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{e}")
                  end
                else
                  @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): "\
                      "skipping child item #{pres_file.uuid} (no item)")
                end
              end
            elsif pres_dir.files.length == 1
              @@logger.info("MedusaCompoundObjectIngester.recreate_binaries(): "\
                    "updating item #{item.repository_id}")

              item.binaries.destroy_all

              # Create the preservation master binary.
              pres_file = pres_dir.files.first
              item.binaries <<
                  pres_file.to_binary(Binary::MasterType::PRESERVATION)
              stats[:num_created] += 1

              # Find and create the access master binary.
              begin
                item.binaries << access_master_binary(top_item_dir, pres_file)
                stats[:num_created] += 1
              rescue IllegalContentError => e
                @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{e}")
              end

              item.save!
            else
              msg = "Preservation directory #{pres_dir.uuid} is empty."
              @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
            end
          else
            msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
                "directory."
            @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
          end

          # Update supplementary item binaries.
          supplementary_dir = top_item_dir.directories.
              select{ |d| d.name == 'supplementary' }.first
          if supplementary_dir
            supplementary_dir.files.each do |supp_file|
              item = Item.find_by_repository_id(supp_file.uuid)
              if item
                item.binaries.destroy_all
                item.binaries << supp_file.to_binary(Binary::MasterType::PRESERVATION)
                item.save!
                stats[:num_created] += 1
              else
                msg = "Supplementary file #{supp_file.uuid} is missing an "\
                    "item counterpart."
                @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
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
                item.binaries << comp_file.to_binary(Binary::MasterType::PRESERVATION)
                item.save!
                stats[:num_created] += 1
              else
                msg = "Composite file #{comp_file.uuid} is missing an "\
                    "item counterpart."
                @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
              end
            end
          end
        else
          msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
          @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
        end
      else
        msg = "No item for directory: #{top_item_dir.uuid}"
        @@logger.warn("MedusaCompoundObjectIngester.recreate_binaries(): #{msg}")
      end
      task.update(percent_complete: index / num_directories.to_f) if task
    end

    # The binaries have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_images_from_cache(item)
      rescue => e
        @@logger.error("MedusaCompoundObjectIngester.recreate_binaries(): "\
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
          return access_file.to_binary(Binary::MasterType::ACCESS)
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

end
