##
# Syncs items in collections that use the {PackageProfile::MIXED_MEDIA_PROFILE
# Mixed Media package profile}.
#
# The mixed media profile looks like:
# * `item_dir`
#     * `child_dir`
#         * `access`
#             * `3d` (optional)
#                 * `file`
#             * `audio` (optional)
#                 * `file`
#             * `images` (optional)
#                 * `file`
#             * `video` (optional)
#                 * `file`
#         * `preservation`
#             * `3d` (optional)
#                 * `file`
#             * `audio` (optional)
#                 * `file`
#             * `images` (optional)
#                 * `file`
#             * `video` (optional)
#                 * `file`
#         * `supplementary` (optional)
#             * `file` (0-*)
#
# @see https://wiki.illinois.edu/wiki/display/LibraryDigitalPreservation/Mixed-Media+Object+package
#
class MedusaMixedMediaIngester < MedusaAbstractIngester

  LOGGER = CustomLogger.new(MedusaMixedMediaIngester)

  ##
  # @param item_id [String] Item repository ID
  # @return [String]
  #
  def self.parent_id_from_medusa(item_id)
    client = Medusa::Client.instance
    json   = client.get_uuid(item_id).body
    struct = JSON.parse(json)

    # Child items will have subdirectories called `access` and/or
    # `preservation`.
    if struct['subdirectories']&.
      find{ |n| %w(access preservation).include?(n['name']) }
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
  # @return [Hash<Symbol,Integer>] Hash with `:num_created`, `:num_updated`,
  #                                and `:num_skipped` keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  # @raises [IllegalContentError]
  #
  def create_items(collection, options = {}, task = nil)
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)
    options = options.symbolize_keys

    stats = { num_created: 0, num_updated: 0, num_skipped: 0 }
    directories = collection.effective_medusa_directory.directories
    num_directories = directories.length

    ActiveRecord::Base.transaction do
      directories.each_with_index do |top_item_dir, index|
        # Find or create the top-level (compound object) item.
        item = Item.find_by_repository_id(top_item_dir.uuid)
        if item
          LOGGER.info('create_items(): skipping item %s', top_item_dir.uuid)
          stats[:num_skipped] += 1
          next
        else
          LOGGER.info('create_items(): creating item %s', top_item_dir.uuid)
          item = Item.new(repository_id: top_item_dir.uuid,
                          collection_repository_id: collection.repository_id)
          # Assign a title of the directory name.
          item.elements.build(name: 'title', value: top_item_dir.name)
          stats[:num_created] += 1
        end

        if top_item_dir.directories.any?
          top_item_dir.directories.each do |child_dir|
            # If the item directory contains only one child directory, assemble
            # the item as standalone with no children.
            if top_item_dir.directories.length == 1
              child = item
            else
              # Find or create the child item.
              child = Item.find_by_repository_id(child_dir.uuid)
              if child
                LOGGER.info('create_items(): skipping child item %s',
                            child_dir.uuid)
                stats[:num_skipped] += 1
                next
              else
                LOGGER.info('create_items(): creating child item %s',
                            child_dir.uuid)
                child = Item.new(repository_id: child_dir.uuid,
                                 collection_repository_id: collection.repository_id,
                                 parent_repository_id: item.repository_id)
                # Assign a title of the filename.
                child.elements.build(name: 'title', value: child_dir.name)
                stats[:num_created] += 1
              end
            end

            # Create the child item's preservation binaries.
            pres_dir = child_dir.directories.find{ |d| d.name == 'preservation' }
            if pres_dir
              if pres_dir.directories.any?
                pres_dir.directories.each do |pres_type_dir|
                  if pres_type_dir.files.any?
                    pres_type_dir.files.each do |pres_file|
                      # Create the preservation master binary.
                      child.binaries << Binary.from_medusa_file(pres_file,
                                                                Binary::MasterType::PRESERVATION,
                                                                media_category_for_master_type(pres_type_dir.name))

                      # Set the child's variant (if it indeed is a child and
                      # not a top-level item referred by a variable named
                      # `child`).
                      if child.parent_repository_id
                        basename = pres_file.name
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
                    end
                  else
                    LOGGER.warn('create_items(): preservation directory %s has no files.',
                                pres_type_dir.uuid)
                  end
                end
              else
                LOGGER.warn('create_items(): preservation directory %s has no subdirectories.',
                            pres_dir.uuid)
              end
            else
              msg = "Directory #{child_dir.uuid} is missing a preservation "\
                "directory."
              LOGGER.warn('create_items(): %s', msg)
            end

            # Create the child's access binaries.
            access_dir = child_dir.directories.find{ |d| d.name == 'access' }
            if access_dir
              if access_dir.directories.any?
                access_dir.directories.each do |access_type_dir|
                  if access_type_dir.files.any?
                    access_type_dir.files.each_with_index do |access_file, afi|
                      # Create the access master binary.
                      child.binaries << Binary.from_medusa_file(access_file,
                                                                Binary::MasterType::ACCESS,
                                                                media_category_for_master_type(access_type_dir.name))

                      if afi == 0 && access_type_dir.name == 'images'
                        child.representative_medusa_file_id = access_file.uuid
                      end
                    end
                  else
                    LOGGER.warn('create_items(): access directory %s has no files.',
                                access_type_dir.uuid)
                  end
                end
              else
                LOGGER.warn('create_items(): access directory %s has no subdirectories.',
                            pres_dir.uuid)
              end
            else
              LOGGER.warn('create_items(): directory %s is missing an access directory.',
                          child_dir.uuid)
            end

            supp_dir = child_dir.directories.find{ |d| d.name == 'supplementary' }
            if supp_dir
              supp_dir.files.each do |supp_file|
                # Find or create the supplementary item.
                child = Item.find_by_repository_id(supp_file.uuid)
                if child
                  LOGGER.info('create_items(): skipping supplementary item %s',
                              supp_file.uuid)
                  stats[:num_skipped] += 1
                else
                  LOGGER.info('create_items(): creating supplementary item %s',
                              supp_file.uuid)
                  child = Item.new(repository_id: supp_file.uuid,
                                   collection_repository_id: collection.repository_id,
                                   parent_repository_id: item.repository_id,
                                   variant: Item::Variants::SUPPLEMENT)
                  # Assign a title of the filename.
                  child.elements.build(name: 'title', value: supp_file.name)
                  child.binaries << Binary.from_medusa_file(supp_file,
                                                            Binary::MasterType::PRESERVATION)
                  child.save!
                  stats[:num_created] += 1
                end
              end
            end
            child.save!
          end
        end

        item.save!

        task.update(percent_complete: index / num_directories.to_f) if task
      end
    end
    stats
  end

  ##
  # Deletes DLS items that are no longer present in Medusa.
  #
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol,Integer>] Hash with `:num_deleted` key.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  # @raises [IllegalContentError]
  #
  def delete_missing_items(collection, task = nil)
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)

    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = items_in(collection.effective_medusa_directory)
    LOGGER.debug('delete_missing_items(): %d items in directory',
                 medusa_items.length)

    stats = { num_deleted: 0 }

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count

    ActiveRecord::Base.transaction do
      items.each_with_index do |item, index|
        unless medusa_items.include?(item.repository_id)
          LOGGER.info('delete_missing_items(): deleting %s', item.repository_id)
          item.destroy!
          stats[:num_deleted] += 1
        end

        if task && index % 10 == 0
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
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>] Hash with `:num_created` key referring to
  #                                 the number of created binaries.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is invalid.
  #
  def recreate_binaries(collection, task = nil)
    check_collection(collection, PackageProfile::MIXED_MEDIA_PROFILE)

    directories = collection.effective_medusa_directory.directories
    num_directories = directories.length

    stats = { num_created: 0 }

    ActiveRecord::Base.transaction do
      directories.each_with_index do |top_item_dir, index|
        # Find the top-level (compound object) item.
        item = Item.find_by_repository_id(top_item_dir.uuid)
        if item
          item.binaries.destroy_all # it shouldn't have any anyway
          item.save!
        end

        if top_item_dir.directories.any?
          top_item_dir.directories.each do |child_dir|
            # If the item directory contains only one child directory, assemble
            # the item as standalone with no children.
            if top_item_dir.directories.length == 1
              child = item
            else
              # Find the child item.
              child = Item.find_by_repository_id(child_dir.uuid)
            end

            if child
              LOGGER.info('recreate_binaries(): updating child item %s',
                          child.repository_id)
              child.binaries.destroy_all

              # Create the child item's preservation binaries.
              pres_dir = child_dir.directories.find{ |d| d.name == 'preservation' }
              if pres_dir
                if pres_dir.directories.any?
                  pres_dir.directories.each do |pres_type_dir|
                    if pres_type_dir.files.any?
                      pres_type_dir.files.each do |pres_file|
                        # Create the preservation master binary.
                        child.binaries << Binary.from_medusa_file(pres_file,
                                                                  Binary::MasterType::PRESERVATION,
                                                                  media_category_for_master_type(pres_type_dir.name))
                        stats[:num_created] += 1
                      end
                    else
                      LOGGER.warn('recreate_binaries(): preservation directory %s has no files.',
                                  pres_type_dir.uuid)
                    end
                  end
                else
                  LOGGER.warn('recreate_binaries(): preservation directory %s has no subdirectories.',
                              pres_dir.uuid)
                end
              else
                LOGGER.warn('recreate_binaries(): directory %s is missing a preservation directory.',
                            child_dir.uuid)
              end

              # Create the child's access binaries.
              access_dir = child_dir.directories.find{ |d| d.name == 'access' }
              if access_dir
                if access_dir.directories.any?
                  access_dir.directories.each do |access_type_dir|
                    if access_type_dir.files.any?
                      access_type_dir.files.each_with_index do |access_file, afi|
                        # Create the access master binary.
                        child.binaries << Binary.from_medusa_file(access_file,
                                                                  Binary::MasterType::ACCESS,
                                                                  media_category_for_master_type(access_type_dir.name))

                        if afi == 0 && access_type_dir.name == 'images'
                          child.representative_medusa_file_id = access_file.uuid
                        end
                        stats[:num_created] += 1
                      end
                    else
                      LOGGER.warn('recreate_binaries(): access directory %s has no files.',
                                  access_type_dir.uuid)
                    end
                  end
                else
                  LOGGER.warn('recreate_binaries(): access directory %s has no subdirectories.',
                              pres_dir.uuid)
                end
              else
                LOGGER.warn('recreate_binaries(): directory %s is missing an access directory.',
                            child_dir.uuid)
              end

              # Create the child's supplementary binaries.
              supp_dir = child_dir.directories.find{ |d| d.name == 'supplementary' }
              if supp_dir
                supp_dir.files.each do |supp_file|
                  item = Item.find_by_repository_id(supp_file.uuid)
                  if item
                    item.binaries.destroy_all
                    item.binaries << Binary.from_medusa_file(supp_file,
                                                             Binary::MasterType::PRESERVATION)
                    item.save!
                    stats[:num_created] += 1
                  else
                    LOGGER.warn('recreate_binaries(): supplementary file %s '\
                                'is missing an item counterpart.',
                                supp_file.uuid)
                  end
                end
              end

              child.save!
            else
              LOGGER.warn('recreate_binaries(): no item for directory: %s',
                          top_item_dir.uuid)
            end
          end
        else
          LOGGER.warn('recreate_binaries(): directory %s has no subdirectories.',
                      top_item_dir.uuid)
        end

        task.update(percent_complete: index / num_directories.to_f) if task
      end

      # The binaries have been updated, but the image server may still have
      # cached versions of the old ones. Here, we will purge them.
      collection.items.each do |item|
        begin
          ImageServer.instance.purge_item_images_from_cache(item)
        rescue => e
          LOGGER.error('recreate_binaries(): failed to purge item from image server cache: %s', e)
        end
      end
    end
    stats
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
  # @param type [String] Name of a directory within a `preservation` or
  #                      `access` directory.
  # @return [Integer] One of the {Binary::MediaCategory} constant values.
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
