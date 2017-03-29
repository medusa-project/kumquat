##
# Syncs items in collections that use the Mixed Media package profile.
#
# The mixed media profile looks like:
# * item_dir
#     * child_dir
#         * access
#             * 3d (optional)
#                 * file
#             * audio (optional)
#                 * file
#             * images (optional)
#                 * file
#             * video (optional)
#                 * file
#         * preservation
#             * 3d (optional)
#                 * file
#             * audio (optional)
#                 * file
#             * images (optional)
#                 * file
#             * video (optional)
#                 * file
#         * supplementary (optional)
#             * file (0-*)
#
# @see https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Mixed-Media+Object+package
#
class MedusaMixedMediaIngester < MedusaAbstractIngester

  @@logger = CustomLogger.instance

  ##
  # @param item_id [String] Item repository ID
  # @return [String]
  #
  def self.parent_id_from_medusa(item_id)
    client = Medusa.client
    json = client.get(Medusa.url(item_id), follow_redirect: true).body
    struct = JSON.parse(json)

    # Child items will have subdirectories called `access` and/or
    # `preservation`.
    if struct['subdirectories']&.
        select{ |n| %w(access preservation).include?(n['name']) }.any?
      return struct['parent_directory']['uuid']
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
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)
    options = options.symbolize_keys

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
      # Find or create the top-level (compound object) item.
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        @@logger.info("MedusaMixedMediaIngester.create_items(): "\
            "skipping item #{top_item_dir.uuid}")
        status[:num_skipped] += 1
        next
      else
        @@logger.info("MedusaMixedMediaIngester.create_items(): "\
            "creating item #{top_item_dir.uuid}")
        item = Item.new(repository_id: top_item_dir.uuid,
                        collection_repository_id: collection.repository_id)
        # Assign a title of the directory name.
        item.elements.build(name: 'title', value: top_item_dir.name)
        status[:num_created] += 1
      end

      if top_item_dir.directories.any?
        top_item_dir.directories.each do |child_dir|
          # Find or create the child item.
          child = Item.find_by_repository_id(child_dir.uuid)
          if child
            @@logger.info("MedusaMixedMediaIngester.create_items(): "\
                  "skipping child item #{child_dir.uuid}")
            status[:num_skipped] += 1
            next
          else
            @@logger.info("MedusaMixedMediaIngester.create_items(): "\
                  "creating child item #{child_dir.uuid}")
            child = Item.new(repository_id: child_dir.uuid,
                             collection_repository_id: collection.repository_id,
                             parent_repository_id: item.repository_id)
            # Assign a title of the filename.
            child.elements.build(name: 'title', value: child_dir.name)
            status[:num_created] += 1
          end

          # Create the child item's preservation binaries.
          pres_dir = child_dir.directories.
              select{ |d| d.name == 'preservation' }.first
          if pres_dir
            if pres_dir.directories.any?
              pres_dir.directories.each do |pres_type_dir|
                if pres_type_dir.files.any?
                  pres_type_dir.files.each do |pres_file|
                    # Create the preservation master binary.
                    child.binaries << pres_file.
                        to_binary(Binary::Type::PRESERVATION_MASTER,
                                  media_category_for_master_type(pres_type_dir.name))

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

                    child.update_from_embedded_metadata(options) if
                        options[:extract_metadata]
                  end
                else
                  msg = "Preservation directory #{pres_type_dir.uuid} has no files."
                  @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
                end
              end
            else
              msg = "Preservation directory #{pres_dir.uuid} has no subdirectories."
              @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
            end
          else
            msg = "Directory #{child_dir.uuid} is missing a preservation "\
              "directory."
            @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
          end

          # Create the child's access binaries.
          access_dir = child_dir.directories.select{ |d| d.name == 'access' }.first
          if access_dir
            if access_dir.directories.any?
              access_dir.directories.each do |access_type_dir|
                if access_type_dir.files.any?
                  access_type_dir.files.each_with_index do |access_file, afi|
                    # Create the access master binary.
                    binary = access_file.to_binary(Binary::Type::ACCESS_MASTER,
                                                   media_category_for_master_type(access_type_dir.name))
                    child.binaries << binary

                    if afi == 0 and access_type_dir.name == 'images'
                      child.representative_binary = binary
                    end
                  end
                else
                  msg = "Access directory #{access_type_dir.uuid} has no files."
                  @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
                end
              end
            else
              msg = "Access directory #{pres_dir.uuid} has no subdirectories."
              @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
            end
          else
            msg = "Directory #{child_dir.uuid} is missing an access "\
              "directory."
            @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
          end

          # If the child item has any supplementary binaries, set its variant
          # to supplement and create them.
          supp_dir = child_dir.directories.
              select{ |d| d.name == 'supplementary' }.first
          if supp_dir
            child.variant = Item::Variants::SUPPLEMENT
            if supp_dir.files.any?
              supp_dir.files.each do |file|
                # Create the supplementary binary.
                child.binaries << file.to_binary(Binary::Type::ACCESS_MASTER)
              end
            else
              msg = "Supplementary directory #{supp_dir.uuid} is empty."
              @@logger.warn("MedusaMixedMediaIngester.create_items(): #{msg}")
            end
          end

          child.save!
        end
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
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)

    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = items_in(collection.effective_medusa_cfs_directory)
    @@logger.debug("MedusaMixedMediaIngester.delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    status = { num_deleted: 0 }
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count
    items.each_with_index do |item, index|
      unless medusa_items.include?(item.repository_id)
        @@logger.info("MedusaMixedMediaIngester.delete_missing_items(): "\
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
  #                                 number of created binaries.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  #
  def update_binaries(collection, task = nil)
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)

    status = { num_created: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
      # Find the top-level (compound object) item.
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        item.binaries.destroy_all # it shouldn't have any anyway
        item.save!
      end

      if top_item_dir.directories.any?
        top_item_dir.directories.each do |child_dir|
          # Find the child item.
          child = Item.find_by_repository_id(child_dir.uuid)
          if child
            @@logger.info("MedusaCompoundObjectIngester.update_binaries(): "\
                      "updating child item #{child.repository_id}")
            child.binaries.destroy_all

            # Create the child item's preservation binaries.
            pres_dir = child_dir.directories.
                select{ |d| d.name == 'preservation' }.first
            if pres_dir
              if pres_dir.directories.any?
                pres_dir.directories.each do |pres_type_dir|
                  if pres_type_dir.files.any?
                    pres_type_dir.files.each do |pres_file|
                      # Create the preservation master binary.
                      child.binaries << pres_file.
                          to_binary(Binary::Type::PRESERVATION_MASTER,
                                    media_category_for_master_type(pres_type_dir.name))
                      status[:num_created] += 1
                    end
                  else
                    msg = "Preservation directory #{pres_type_dir.uuid} has no files."
                    @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
                  end
                end
              else
                msg = "Preservation directory #{pres_dir.uuid} has no subdirectories."
                @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
              end
            else
              msg = "Directory #{child_dir.uuid} is missing a preservation "\
              "directory."
              @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
            end

            # Create the child's access binaries.
            access_dir = child_dir.directories.
                select{ |d| d.name == 'access' }.first
            if access_dir
              if access_dir.directories.any?
                access_dir.directories.each do |access_type_dir|
                  if access_type_dir.files.any?
                    access_type_dir.files.each_with_index do |access_file, afi|
                      # Create the access master binary.
                      binary = access_file.to_binary(Binary::Type::ACCESS_MASTER,
                                                     media_category_for_master_type(access_type_dir.name))
                      child.binaries << binary

                      if afi == 0 and access_type_dir.name == 'images'
                        child.representative_binary = binary
                      end
                      status[:num_created] += 1
                    end
                  else
                    msg = "Access directory #{access_type_dir.uuid} has no files."
                    @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
                  end
                end
              else
                msg = "Access directory #{pres_dir.uuid} has no subdirectories."
                @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
              end
            else
              msg = "Directory #{child_dir.uuid} is missing an access "\
                "directory."
              @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
            end

            # Create the child's supplementary binaries.
            supp_dir = child_dir.directories.
                select{ |d| d.name == 'supplementary' }.first
            if supp_dir
              if supp_dir.files.any?
                supp_dir.files.each do |file|
                  # Create the supplementary binary.
                  child.binaries << file.to_binary(Binary::Type::ACCESS_MASTER)
                  status[:num_created] += 1
                end
              else
                msg = "Supplementary directory #{supp_dir.uuid} is empty."
                @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
              end
            end

            child.save!
          else
            msg = "No item for directory: #{top_item_dir.uuid}"
            @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
          end
        end
      else
        msg = "Directory #{top_item_dir.uuid} has no subdirectories."
        @@logger.warn("MedusaMixedMediaIngester.update_binaries(): #{msg}")
      end

      task.update(percent_complete: index / num_directories.to_f) if task
    end
    status

    # The binaries have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_from_cache(item)
      rescue => e
        @@logger.error("MedusaMixedMediaIngester.update_binaries(): "\
            "failed to purge item from image server cache: #{e}")
      end
    end
    status
  end

  private

  ##
  # @param root_cfs_dir [String] Root CFS directory.
  # @return [Set<String>] Set of all item UUIDs in a CFS directory using the
  #                       mixed media package profile.
  #
  def items_in(root_cfs_dir)
    medusa_item_uuids = Set.new
    root_cfs_dir.directories.each do |top_item_dir|
      medusa_item_uuids << top_item_dir.uuid
      top_item_dir.directories.each do |subdir|
        medusa_item_uuids << subdir.uuid
      end
    end
    medusa_item_uuids
  end

  ##
  # @param type [String] Name of a directory within a "preservation" or
  #                      "access" directory.
  # @return [Integer] One of the Binary::MediaCategory constant values.
  #
  def media_category_for_master_type(type)
    case type
      when '3d'
        return Binary::MediaCategory::THREE_D
      when 'audio'
        return Binary::MediaCategory::AUDIO
      when 'images'
        return Binary::MediaCategory::IMAGE
      when 'video'
        return Binary::MediaCategory::VIDEO
    end
    nil
  end

end
