class MedusaIngester

  class IngestMode
    # Creates new DLS entities but does not touch existing DLS entities.
    CREATE_ONLY = 'create_only'

    # Deletes DLS entities that have gone missing in Medusa, but does not
    # create or update anything.
    DELETE_MISSING = 'delete_missing'

    # Updates existing DLS items' bytestreams.
    UPDATE_BYTESTREAMS = 'update_bytestreams'
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

    Rails.logger.info('MedusaIngester.ingest_collections(): '\
        'retrieving collection list')
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
  # collection's package profile.
  #
  # @param collection [Collection]
  # @param mode [String] One of the IngestMode constants.
  # @param options [Hash] Options hash.
  # @option options [Boolean] :extract_metadata
  # @param warnings [Array<String>] Array which will be populated with nonfatal
  #                                 warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated,
  #                                :num_deleted, and/or :num_skipped keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is set to an
  #                         external store.
  # @raises [IllegalContentError]
  #
  def ingest_items(collection, mode, options = {}, warnings = [])
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory

    options = options.symbolize_keys
    stats = { num_deleted: 0, num_created: 0, num_updated: 0, num_skipped: 0 }

    ActiveRecord::Base.transaction do
      case mode
        when IngestMode::DELETE_MISSING
          stats.merge!(delete_missing_items(collection))
        when IngestMode::UPDATE_BYTESTREAMS
          stats.merge!(update_bytestreams(collection, warnings))
        else
          stats.merge!(create_items(collection, options, warnings))
      end
    end
    stats
  end

  private

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_free_form_items(collection, options)
    ##
    # @param collection [Collection]
    # @param cfs_dir [MedusaCfsDirectory]
    # @param top_cfs_dir [MedusaCfsDirectory]
    # @param options [Hash]
    # @option options [Boolean] :extract_metadata
    # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
    #                                :num_skipped keys.
    #
    def walk_tree(collection, cfs_dir, top_cfs_dir, options, status)
      cfs_dir.directories.each do |dir|
        item = Item.find_by_repository_id(dir.uuid)
        if item
          Rails.logger.info("ingest_free_form_items(): skipping item "\
              "#{dir.uuid}")
          status[:num_skipped] += 1
        else
          Rails.logger.info("ingest_free_form_items(): creating item "\
                    "#{dir.uuid}")
          item = Item.new(repository_id: dir.uuid,
                          parent_repository_id: (cfs_dir.uuid != top_cfs_dir.uuid) ? cfs_dir.uuid : nil,
                          collection_repository_id: collection.repository_id,
                          variant: Item::Variants::DIRECTORY)
          # Assign a title of the directory name.
          e = item.elements.build
          e.name = 'title'
          e.value = dir.name
          item.save!
          status[:num_created] += 1
        end
        walk_tree(collection, dir, top_cfs_dir, options, status)
      end
      cfs_dir.files.each do |file|
        item = Item.find_by_repository_id(file.uuid)
        if item
          Rails.logger.info("ingest_free_form_items(): skipping item "\
                "#{file.uuid}")
          status[:num_skipped] += 1
          next
        else
          Rails.logger.info("ingest_free_form_items(): creating item "\
                      "#{file.uuid}")
          item = Item.new(repository_id: file.uuid,
                          parent_repository_id: (cfs_dir.uuid != top_cfs_dir.uuid) ? cfs_dir.uuid : nil,
                          collection_repository_id: collection.repository_id,
                          variant: Item::Variants::FILE)
          # Create its corresponding bytestream.
          bs = item.bytestreams.build
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.cfs_file_uuid = file.uuid
          bs.repository_relative_pathname =
              '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
          bs.infer_media_type # The type of the CFS file cannot be trusted.

          # Populate its metadata from embedded bytestream metadata.
          item.update_from_embedded_metadata if options[:extract_metadata]

          # If there was no title available in the embedded metadata, assign a
          # title of the filename.
          if item.elements.select{ |e| e.name == 'title' }.empty?
            e = item.elements.build
            e.name = 'title'
            e.value = file.name
          end

          item.save!
          status[:num_created] += 1
        end
      end
    end

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    walk_tree(collection, collection.effective_medusa_cfs_directory,
        collection.effective_medusa_cfs_directory, options, status)
    status
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @param warnings [Array<String>] Array which will be populated with
  #                                 nonfatal warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_items(collection, options, warnings = [])
    case collection.package_profile
      when PackageProfile::FREE_FORM_PROFILE
        return create_free_form_items(collection, options)
      when PackageProfile::MAP_PROFILE
        return create_map_items(collection, options, warnings)
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        return create_single_items(collection, options, warnings)
      else
        raise IllegalContentError,
              "create_items(): unrecognized package profile: "\
                    "#{collection.package_profile}"
    end
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_map_items(collection, options, warnings = [])
    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    collection.effective_medusa_cfs_directory.directories.each do |top_item_dir|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        Rails.logger.info("ingest_map_items(): skipping item "\
            "#{top_item_dir.uuid}")
        status[:num_skipped] += 1
        next
      else
        Rails.logger.info("ingest_map_items(): creating item "\
                    "#{top_item_dir.uuid}")
        item = Item.new(repository_id: top_item_dir.uuid,
                        collection_repository_id: collection.repository_id)
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
                Rails.logger.info("ingest_map_items(): skipping child item "\
                    "#{pres_file.uuid}")
                status[:num_skipped] += 1
                next
              else
                Rails.logger.info("ingest_map_items(): creating child item "\
                    "#{pres_file.uuid}")
                child = Item.new(repository_id: pres_file.uuid,
                                 collection_repository_id: collection.repository_id,
                                 parent_repository_id: item.repository_id)
                status[:num_created] += 1
              end

              # Create the preservation master bytestream.
              bs = child.bytestreams.build
              bs.cfs_file_uuid = pres_file.uuid
              bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
              bs.repository_relative_pathname =
                  '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
              bs.infer_media_type # The type of the CFS file cannot be trusted.

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

              # Find and create the access master bytestream.
              begin
                bs = map_access_master_bytestream(top_item_dir, pres_file)
                child.bytestreams << bs
              rescue IllegalContentError => e
                warnings << "#{e}"
              end

              child.update_from_embedded_metadata if options[:extract_metadata]

              child.save!
            end
          elsif pres_dir.files.length == 1
            # Create the preservation master bytestream.
            pres_file = pres_dir.files.first
            bs = item.bytestreams.build
            bs.cfs_file_uuid = pres_file.uuid
            bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
            bs.repository_relative_pathname =
                '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
            bs.infer_media_type # The type of the CFS file cannot be trusted.

            # Find and create the access master bytestream.
            begin
              bs = map_access_master_bytestream(top_item_dir, pres_file)
              item.bytestreams << bs
            rescue IllegalContentError => e
              warnings << "#{e}"
            end

            item.update_from_embedded_metadata if options[:extract_metadata]
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
        Rails.logger.warn('ingest_map_items(): ' + msg)
        warnings << msg
      end

      item.save!
    end
    status
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_single_items(collection, options, warnings = [])
    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    pres_dir.files.each do |file|
      # Find or create the child item.
      item = Item.find_by_repository_id(file.uuid)
      if item
        Rails.logger.info("ingest_single_items(): skipping item #{file.uuid}")
        status[:num_skipped] += 1
        next
      else
        Rails.logger.info("ingest_single_items(): creating item #{file.uuid}")
        item = Item.new(repository_id: file.uuid,
                        collection_repository_id: collection.repository_id)
        status[:num_created] += 1
      end

      # Create the preservation master bytestream.
      bs = item.bytestreams.build
      bs.cfs_file_uuid = file.uuid
      bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
      bs.repository_relative_pathname =
          '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
      bs.media_type = file.media_type

      # Find and create the access master bytestream.
      begin
        item.bytestreams << single_item_access_master_bytestream(cfs_dir, file)
      rescue IllegalContentError => e
        warnings << "#{e}"
      end

      item.update_from_embedded_metadata if options[:extract_metadata]

      item.save!
    end
    status
  end

  ##
  # @param collection [Collection]
  # @return [Hash<Symbol,Integer>] Hash with :num_deleted key.
  # @raises [IllegalContentError]
  #
  def delete_missing_items(collection)
    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = free_form_items_in(collection.effective_medusa_cfs_directory)
    Rails.logger.debug("delete_missing_items(): "\
        "#{medusa_items.length} items in CFS directory")

    case collection.package_profile
      when PackageProfile::FREE_FORM_PROFILE
        medusa_items = free_form_items_in(collection.effective_medusa_cfs_directory)
      when PackageProfile::MAP_PROFILE
        medusa_items = map_items_in(collection.effective_medusa_cfs_directory)
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        medusa_items = single_items_in(collection.effective_medusa_cfs_directory)
      else
        raise IllegalContentError,
              'delete_missing_items(): unrecognized collection content profile.'
    end

    # For each DLS item in the collection, if it's no longer contained in the
    # file group, delete it.
    status = { num_deleted: 0 }
    Item.where(collection_repository_id: collection.repository_id).each do |item|
      unless medusa_items.include?(item.repository_id)
        Rails.logger.info("delete_missing_items(): deleting "\
          "#{item.repository_id}")
        item.destroy!
        status[:num_deleted] += 1
      end
    end
    status
  end

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @return [Set<String>] Set of item UUIDs
  #
  def free_form_items_in(cfs_dir)
    ##
    # @param cfs_dir [Collection]
    # @param medusa_item_uuids [Set<String>]
    # @return [void]
    #
    def walk_tree(cfs_dir, medusa_item_uuids)
      cfs_dir.directories.each do |dir|
        medusa_item_uuids << dir.uuid
        walk_tree(dir, medusa_item_uuids)
      end
      cfs_dir.files.each do |file|
        medusa_item_uuids << file.uuid
      end
    end

    medusa_item_uuids = Set.new
    walk_tree(cfs_dir, medusa_item_uuids)
    medusa_item_uuids
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
          bs.cfs_file_uuid = access_file.uuid
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname =
              '/' + access_file.repository_relative_pathname.reverse.chomp('/').reverse
          bs.infer_media_type # The type of the CFS file cannot be trusted.
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
  # @return [Set<String>] Set of all item UUIDs in a CFS directory using the
  #                       map content profile.
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

  ##
  # @param cfs_dir [MedusaCfsDirectory]
  # @param pres_master_file [MedusaCfsFile]
  # @return [Bytestream]
  # @raises [IllegalContentError]
  #
  def single_item_access_master_bytestream(cfs_dir, pres_master_file)
    # Works the same way.
    map_access_master_bytestream(cfs_dir, pres_master_file)
  end

  ##
  # @return [Set<String>] Set of all item UUIDs in a CFS directory using the
  #                       single-item object content profile.
  #
  def single_items_in(cfs_dir)
    medusa_item_uuids = Set.new
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first
    if pres_dir
      pres_dir.files.each { |file| medusa_item_uuids << file.uuid }
    end
    medusa_item_uuids
  end

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Will be populated with nonfatal warnings
  #                                 (optional).
  # @return [Hash<Symbol, Integer>]
  #
  def update_bytestreams(collection, warnings = [])
    case collection.package_profile
      when PackageProfile::FREE_FORM_PROFILE
        return update_free_form_bytestreams(collection)
      when PackageProfile::MAP_PROFILE
        return update_map_bytestreams(collection, warnings)
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        return update_single_item_bytestreams(collection, warnings)
      else
        raise IllegalContentError,
              "update_bytestreams(): unrecognized package profile: "\
                    "#{collection.package_profile}"
    end
  end

  ##
  # @param collection [Collection]
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_free_form_bytestreams(collection)
    ##
    # @param collection [Collection]
    # @param cfs_dir [MedusaCfsDirectory]
    # @param top_cfs_dir [MedusaCfsDirectory]
    # @param stats [Hash<Symbol,Integer>]
    # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
    #
    def walk_tree(collection, cfs_dir, top_cfs_dir, stats)
      cfs_dir.directories.each do |dir|
        walk_tree(collection, dir, top_cfs_dir, stats)
      end
      cfs_dir.files.each do |file|
        item = Item.find_by_repository_id(file.uuid)
        if item
          Rails.logger.info("update_free_form_bytestreams(): updating "\
                            "bytestreams for item: #{file.uuid}")

          item.bytestreams.destroy_all

          bs = item.bytestreams.build
          bs.bytestream_type = Bytestream::Type::ACCESS_MASTER
          bs.cfs_file_uuid = file.uuid
          bs.repository_relative_pathname =
              '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
          bs.infer_media_type # The type of the CFS file cannot be trusted.
          bs.save!

          stats[:num_updated] += 1
        end
      end
    end

    stats = { num_updated: 0 }
    walk_tree(collection, collection.effective_medusa_cfs_directory,
              collection.effective_medusa_cfs_directory, stats)
    stats
  end

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_map_bytestreams(collection, warnings = [])
    stats = { num_updated: 0 }
    collection.effective_medusa_cfs_directory.directories.each do |top_item_dir|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
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
                  Rails.logger.info("update_map_bytestreams(): updating child item "\
                    "#{pres_file.uuid}")

                  child.bytestreams.destroy_all

                  # Create the preservation master bytestream.
                  bs = child.bytestreams.build
                  bs.cfs_file_uuid = pres_file.uuid
                  bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
                  bs.repository_relative_pathname =
                      '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
                  bs.infer_media_type # The type of the CFS file cannot be trusted.
                  bs.save!

                  # Find and create the access master bytestream.
                  begin
                    bs = map_access_master_bytestream(top_item_dir, pres_file)
                    bs.item = child
                    bs.save!
                  rescue IllegalContentError => e
                    warnings << "#{e}"
                  end
                  stats[:num_updated] += 1
                else
                  Rails.logger.warn("update_map_bytestreams(): skipping child item "\
                    "#{pres_file.uuid} (no item)")
                end
              end
            elsif pres_dir.files.length == 1
              Rails.logger.info("update_map_bytestreams(): updating item "\
                    "#{item.repository_id}")

              item.bytestreams.destroy_all

              # Create the preservation master bytestream.
              pres_file = pres_dir.files.first
              bs = item.bytestreams.build
              bs.cfs_file_uuid = pres_file.uuid
              bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
              bs.repository_relative_pathname =
                  '/' + pres_file.repository_relative_pathname.reverse.chomp('/').reverse
              bs.infer_media_type # The type of the CFS file cannot be trusted.

              # Find and create the access master bytestream.
              begin
                bs = map_access_master_bytestream(top_item_dir, pres_file)
                item.bytestreams << bs
              rescue IllegalContentError => e
                warnings << "#{e}"
              end

              item.save!

              stats[:num_updated] += 1
            else
              msg = "Preservation directory #{pres_dir.uuid} is empty."
              Rails.logger.warn('update_map_bytestreams(): ' + msg)
              warnings << msg
            end
          else
            msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
                "directory."
            Rails.logger.warn('update_map_bytestreams(): ' + msg)
            warnings << msg
          end
        else
          msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
          Rails.logger.warn('update_map_bytestreams(): ' + msg)
          warnings << msg
        end
      else
        msg = "No item for directory: #{top_item_dir.uuid}"
        Rails.logger.warn('update_map_bytestreams(): ' + msg)
        warnings << msg
      end
    end
    stats
  end

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_single_item_bytestreams(collection, warnings = [])
    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    stats = { num_updated: 0 }
    pres_dir.files.each do |file|
      item = Item.find_by_repository_id(file.uuid)
      if item
        item.bytestreams.destroy_all

        # Create the preservation master bytestream.
        bs = item.bytestreams.build
        bs.cfs_file_uuid = file.uuid
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.repository_relative_pathname =
            '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
        bs.media_type = file.media_type
        bs.save!

        # Find and create the access master bytestream.
        begin
          bs = single_item_access_master_bytestream(cfs_dir, file)
          bs.item = item
          bs.save!
        rescue IllegalContentError => e
          warnings << "#{e}"
        end

        stats[:num_updated] += 1
      end
    end
    stats
  end

end
