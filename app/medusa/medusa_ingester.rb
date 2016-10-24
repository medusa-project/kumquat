class MedusaIngester

  class IngestMode
    # Creates new DLS entities but does not touch existing DLS entities.
    CREATE_ONLY = :create_only
    # Deletes DLS entities that have gone missing in Medusa, but does not
    # create or update anything.
    DELETE_MISSING = :delete_missing
    # Replaces DLS items' metadata with that found in embedded metadata.
    REPLACE_METADATA = :replace_metadata
    # Updates existing DLS items' bytestreams.
    UPDATE_BYTESTREAMS = :update_bytestreams
  end

  ##
  # Retrieves the current list of Medusa collections from the Medusa REST API
  # and creates or updates the local Collection counterpart instances.
  #
  # @param task [Task] Required for progress reporting
  # @return [void]
  #
  def ingest_collections(task = nil)
    config = Configuration.instance
    url = sprintf('%s/collections.json', config.medusa_url.chomp('/'))

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
  # @option options [Boolean] :include_date_created
  # @param warnings [Array<String>] Array which will be populated with nonfatal
  #                                 warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated,
  #                                :num_deleted, and/or :num_skipped keys.
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set, or if the file group is set to an
  #                         external store.
  # @raises [IllegalContentError]
  #
  def ingest_items(collection, mode, options = {}, warnings = [], task = nil)
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory

    options = options.symbolize_keys
    stats = { num_deleted: 0, num_created: 0, num_updated: 0, num_skipped: 0 }

    ActiveRecord::Base.transaction do
      case mode.to_sym
        when IngestMode::DELETE_MISSING
          stats.merge!(delete_missing_items(collection, task))
        when IngestMode::UPDATE_BYTESTREAMS
          stats.merge!(update_bytestreams(collection, warnings, task))
        when IngestMode::REPLACE_METADATA
          stats.merge!(replace_metadata(collection, task))
        else
          stats.merge!(create_items(collection, options, warnings, task))
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
      count += count_tree_nodes(dir, count)
    end
    count += cfs_dir.files.length
    count
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @param task [Task] Supply to receive progress updates.
  # @option options [Boolean] :extract_metadata
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_free_form_items(collection, options, task = nil)
    if task
      # Compile a count of filesystem nodes in order to display progress
      # updates.
      num_nodes = count_tree_nodes(collection.effective_medusa_cfs_directory)
    else
      num_nodes = 0
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
    # @param num_walked [Integer] For internal use.
    # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
    #                                :num_skipped keys.
    #
    def walk_tree(collection, cfs_dir, top_cfs_dir, options, status,
                  task = nil, num_nodes = 0, num_walked = 0)
      cfs_dir.directories.each do |dir|
        item = Item.find_by_repository_id(dir.uuid)
        if item
          Rails.logger.info("MedusaIngester.create_free_form_items(): "\
              "skipping item #{dir.uuid}")
          status[:num_skipped] += 1
        else
          Rails.logger.info("MedusaIngester.create_free_form_items(): "\
              "creating item #{dir.uuid}")
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

        if task
          task.update(percent_complete: num_walked / num_nodes.to_f)
        end

        num_walked += 1

        walk_tree(collection, dir, top_cfs_dir, options, status, task,
                  num_nodes, num_walked)
      end
      cfs_dir.files.each do |file|
        item = Item.find_by_repository_id(file.uuid)
        if item
          Rails.logger.info("MedusaIngester.create_free_form_items(): "\
                "skipping item #{file.uuid}")
          status[:num_skipped] += 1
          next
        else
          Rails.logger.info("MedusaIngester.create_free_form_items(): "\
                "creating item #{file.uuid}")
          item = Item.new(repository_id: file.uuid,
                          parent_repository_id: (cfs_dir.uuid != top_cfs_dir.uuid) ? cfs_dir.uuid : nil,
                          collection_repository_id: collection.repository_id,
                          variant: Item::Variants::FILE)
          item.elements.build(name: 'title', value: file.name)

          # Create its corresponding bytestream.
          bs = file.to_bytestream(Bytestream::Type::ACCESS_MASTER)
          bs.item = item
          bs.save!

          update_item_from_embedded_metadata(item, options) if
              options[:extract_metadata]

          item.save!
          status[:num_created] += 1
        end

        if task
          task.update(percent_complete: num_walked / num_nodes.to_f)
        end
        num_walked += 1
      end
    end

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    walk_tree(collection, collection.effective_medusa_cfs_directory,
        collection.effective_medusa_cfs_directory, options, status, task,
              num_nodes)
    status
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @param warnings [Array<String>] Array which will be populated with
  #                                 nonfatal warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_items(collection, options, warnings = [], task = nil)
    case collection.package_profile
      when PackageProfile::FREE_FORM_PROFILE
        return create_free_form_items(collection, options, task)
      when PackageProfile::MAP_PROFILE
        return create_map_items(collection, options, warnings, task)
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        return create_single_items(collection, options, warnings, task)
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
  # @option options [Boolean] :include_date_created
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_map_items(collection, options, warnings = [], task = nil)
    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
      item = Item.find_by_repository_id(top_item_dir.uuid)
      if item
        Rails.logger.info("MedusaIngester.create_map_items(): skipping item "\
            "#{top_item_dir.uuid}")
        status[:num_skipped] += 1
        next
      else
        Rails.logger.info("MedusaIngester.create_map_items(): creating item "\
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
                Rails.logger.info("MedusaIngester.create_map_items(): "\
                    "skipping child item #{pres_file.uuid}")
                status[:num_skipped] += 1
                next
              else
                Rails.logger.info("MedusaIngester.create_map_items(): "\
                    "creating child item #{pres_file.uuid}")
                child = Item.new(repository_id: pres_file.uuid,
                                 collection_repository_id: collection.repository_id,
                                 parent_repository_id: item.repository_id)
                status[:num_created] += 1
              end

              # Create the preservation master bytestream.
              child.bytestreams << pres_file.
                  to_bytestream(Bytestream::Type::PRESERVATION_MASTER)

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

              child.update_from_embedded_metadata(options) if
                  options[:extract_metadata]

              child.save!
            end
          elsif pres_dir.files.length == 1
            # Create the preservation master bytestream.
            pres_file = pres_dir.files.first
            item.bytestreams << pres_file.
                to_bytestream(Bytestream::Type::PRESERVATION_MASTER)

            # Find and create the access master bytestream.
            begin
              bs = map_access_master_bytestream(top_item_dir, pres_file)
              item.bytestreams << bs
            rescue IllegalContentError => e
              warnings << "#{e}"
            end

            item.update_from_embedded_metadata(options) if
                options[:extract_metadata]
          else
            msg = "Preservation directory #{pres_dir.uuid} is empty."
            Rails.logger.warn("MedusaIngester.create_map_items(): #{msg}")
            warnings << msg
          end
        else
          msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
              "directory."
          Rails.logger.warn("MedusaIngester.create_map_items(): #{msg}")
          warnings << msg
        end
      else
        msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
        Rails.logger.warn("MedusaIngester.create_map_items(): #{msg}")
        warnings << msg
      end

      item.save!

      task.update(percent_complete: index / num_directories.to_f) if task
    end
    status
  end

  ##
  # @param collection [Collection]
  # @param options [Hash]
  # @option options [Boolean] :extract_metadata
  # @option options [Boolean] :include_date_created
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with :num_created, :num_updated, and
  #                                :num_skipped keys.
  #
  def create_single_items(collection, options, warnings = [], task = nil)
    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    status = { num_created: 0, num_updated: 0, num_skipped: 0 }
    files = pres_dir.files
    num_files = files.length
    files.each_with_index do |file, index|
      # Find or create the child item.
      item = Item.find_by_repository_id(file.uuid)
      if item
        Rails.logger.info("MedusaIngester.create_single_items(): skipping "\
            "item #{file.uuid}")
        status[:num_skipped] += 1
        next
      else
        Rails.logger.info("MedusaIngester.create_single_items(): creating "\
            "item #{file.uuid}")
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
      bs.byte_size = File.size(bs.absolute_local_pathname)
      bs.media_type = file.media_type

      # Find and create the access master bytestream.
      begin
        item.bytestreams << single_item_access_master_bytestream(cfs_dir, file)
      rescue IllegalContentError => e
        warnings << "#{e}"
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
  #
  def delete_missing_items(collection, task = nil)
    # Compile a list of all item UUIDs currently in the Medusa file group.
    medusa_items = free_form_items_in(collection.effective_medusa_cfs_directory)
    Rails.logger.debug("MedusaIngester.delete_missing_items(): "\
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
    items = Item.where(collection_repository_id: collection.repository_id)
    num_items = items.count
    items.each_with_index do |item, index|
      unless medusa_items.include?(item.repository_id)
        Rails.logger.info("MedusaIngester.delete_missing_items(): deleting "\
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
          return access_file.to_bytestream(Bytestream::Type::ACCESS_MASTER)
        else
          msg = "Preservation master file #{pres_master_file.uuid} has no "\
              "access master counterpart."
          Rails.logger.warn("MedusaIngester.map_access_master_bytestream(): #{msg}")
          raise IllegalContentError, msg
        end
      else
        msg = "Access master directory #{access_dir.uuid} has no files."
        Rails.logger.warn("MedusaIngester.map_access_master_bytestream(): #{msg}")
        raise IllegalContentError, msg
      end
    else
      msg = "Item directory #{item_cfs_dir.uuid} is missing an access "\
          "master subdirectory."
      Rails.logger.warn("MedusaIngester.map_access_master_bytestream(): #{msg}")
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
  # @param collection [Collection]
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def replace_metadata(collection, task = nil)
    stats = { num_updated: 0 }
    # Skip items derived from directories, as they have no embedded metadata.
    items = collection.items.where('variant != ?', Item::Variants::DIRECTORY)
    num_items = items.count
    items.each_with_index do |item, index|
      Rails.logger.info("MedusaIngester.replace_metadata(): #{item.repository_id}")
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
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol, Integer>]
  #
  def update_bytestreams(collection, warnings = [], task = nil)
    case collection.package_profile
      when PackageProfile::FREE_FORM_PROFILE
        stats = update_free_form_bytestreams(collection, task)
      when PackageProfile::MAP_PROFILE
        stats = update_map_bytestreams(collection, warnings, task)
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        stats = update_single_item_bytestreams(collection, warnings, task)
      else
        raise IllegalContentError,
              "update_bytestreams(): unrecognized package profile: "\
                    "#{collection.package_profile}"
    end

    # The bytestreams have been updated, but the image server may still have
    # cached versions of the old ones. Here, we will use the Cantaloupe API to
    # purge them.
    collection.items.each do |item|
      begin
        ImageServer.instance.purge_item_from_cache(item)
      rescue => e
        Rails.logger.error("MedusaIngester.update_bytestreams(): failed to "\
            "purge item from image server cache: #{e}")
      end
    end

    stats
  end

  ##
  # @param collection [Collection]
  # @param task [Task] Supply to receive status updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_free_form_bytestreams(collection, task = nil)
    if task
      # Compile a count of filesystem nodes in order to display progress
      # updates.
      num_nodes = count_tree_nodes(collection.effective_medusa_cfs_directory)
    else
      num_nodes = 0
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
    def walk_tree(cfs_dir, top_cfs_dir, stats, task = nil, num_nodes = 0,
                  num_walked = 0)
      cfs_dir.directories.each do |dir|
        if task and num_walked % 10 == 0
          task.update(percent_complete: num_walked / num_nodes.to_f)
        end
        num_walked += 1
        walk_tree(dir, top_cfs_dir, stats)
      end
      cfs_dir.files.each do |file|
        if task and num_walked % 10 == 0
          task.update(percent_complete: num_walked / num_nodes.to_f)
        end
        num_walked += 1
        item = Item.find_by_repository_id(file.uuid)
        if item
          Rails.logger.info("MedusaIngester.update_free_form_bytestreams(): "\
                            "updating bytestreams for item: #{file.uuid}")

          item.bytestreams.destroy_all

          bs = file.to_bytestream(Bytestream::Type::ACCESS_MASTER)
          bs.item = item
          bs.save!

          stats[:num_updated] += 1
        end
      end
    end

    stats = { num_updated: 0 }
    walk_tree(collection.effective_medusa_cfs_directory,
              collection.effective_medusa_cfs_directory, stats, task, num_nodes)
    stats
  end

  ##
  # Populates an item's metadata from its embedded bytestream metadata.
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

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_map_bytestreams(collection, warnings = [], task = nil)
    stats = { num_updated: 0 }
    directories = collection.effective_medusa_cfs_directory.directories
    num_directories = directories.length

    directories.each_with_index do |top_item_dir, index|
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
                  Rails.logger.info("MedusaIngester.update_map_bytestreams(): "\
                      "updating child item #{pres_file.uuid}")

                  child.bytestreams.destroy_all

                  # Create the preservation master bytestream.
                  bs = pres_file.to_bytestream(Bytestream::Type::PRESERVATION_MASTER)
                  bs.item = child
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
                  Rails.logger.warn("MedusaIngester.update_map_bytestreams(): "\
                      "skipping child item #{pres_file.uuid} (no item)")
                end
              end
            elsif pres_dir.files.length == 1
              Rails.logger.info("MedusaIngester.update_map_bytestreams(): "\
                    "updating item #{item.repository_id}")

              item.bytestreams.destroy_all

              # Create the preservation master bytestream.
              pres_file = pres_dir.files.first
              item.bytestreams << pres_file.
                  to_bytestream(Bytestream::Type::PRESERVATION_MASTER)

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
              Rails.logger.warn("MedusaIngester.update_map_bytestreams(): #{msg}")
              warnings << msg
            end
          else
            msg = "Directory #{top_item_dir.uuid} is missing a preservation "\
                "directory."
            Rails.logger.warn("MedusaIngester.update_map_bytestreams(): #{msg}")
            warnings << msg
          end
        else
          msg = "Directory #{top_item_dir.uuid} does not have any subdirectories."
          Rails.logger.warn("MedusaIngester.update_map_bytestreams(): #{msg}")
          warnings << msg
        end
      else
        msg = "No item for directory: #{top_item_dir.uuid}"
        Rails.logger.warn("MedusaIngester.update_map_bytestreams(): #{msg}")
        warnings << msg
      end
      task.update(percent_complete: index / num_directories.to_f) if task
    end
    stats
  end

  ##
  # @param collection [Collection]
  # @param warnings [Array<String>] Supply an array which will be populated
  #                                 with nonfatal warnings (optional).
  # @param task [Task] Supply to receive progress updates.
  # @return [Hash<Symbol,Integer>] Hash with a :num_updated key.
  #
  def update_single_item_bytestreams(collection, warnings = [], task = nil)
    cfs_dir = collection.effective_medusa_cfs_directory
    pres_dir = cfs_dir.directories.select{ |d| d.name == 'preservation' }.first

    stats = { num_updated: 0 }
    files = pres_dir.files
    num_files = files.length
    files.each_with_index do |file, index|
      item = Item.find_by_repository_id(file.uuid)
      if item
        item.bytestreams.destroy_all

        # Create the preservation master bytestream.
        bs = item.bytestreams.build
        bs.cfs_file_uuid = file.uuid
        bs.bytestream_type = Bytestream::Type::PRESERVATION_MASTER
        bs.repository_relative_pathname =
            '/' + file.repository_relative_pathname.reverse.chomp('/').reverse
        bs.byte_size = File.size(bs.absolute_local_pathname)
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

      if task and index % 10 == 0
        task.update(percent_complete: index / num_files.to_f)
      end
    end
    stats
  end

end
