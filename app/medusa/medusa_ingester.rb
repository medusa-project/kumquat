class MedusaIngester

  class IngestMode
    # Creates new DLS entities but does not touch existing DLS entities.
    CREATE_ONLY = :create_only
    # Deletes DLS entities that have gone missing in Medusa, but does not
    # create or update anything.
    DELETE_MISSING = :delete_missing
    # Replaces items' metadata with that found in embedded metadata.
    REPLACE_METADATA = :replace_metadata
    # Updates existing items' binaries.
    UPDATE_BINARIES = :update_binaries
  end

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
    ingester_for(collection).create_items(collection, options, task)
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
    ingester_for(collection).delete_missing_items(collection, task)
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
    ingester_for(collection).replace_metadata(collection, task)
  end

  ##
  # Retrieves the current list of Medusa collections from the Medusa REST API
  # and creates or updates the local Collection counterpart instances.
  #
  # @param task [Task] Required for progress reporting
  # @return [void]
  #
  def sync_collections(task = nil)
    config = Configuration.instance
    url = sprintf('%s/collections.json', config.medusa_url.chomp('/'))

    # Download the list of collections from Medusa.
    @@logger.info('MedusaIngester.sync_collections(): '\
        'downloading collection list')
    response = Medusa.client.get(url, follow_redirect: true)
    struct = JSON.parse(response.body)

    ActiveRecord::Base.transaction do
      # Create or update a DLS counterpart of each collection.
      struct.each_with_index do |st, index|
        col = Collection.find_or_create_by(repository_id: st['uuid'])
        col.update_from_medusa

        if task and index % 10 == 0
          task.percent_complete = index / struct.length.to_f
          task.save
        end
      end

      # Delete any DLS collections that are no longer present in Medusa (but
      # not any items within them, to be safe).
      Collection.all.each do |col|
        if struct.select { |st| st['uuid'] == col.repository_id }.empty?
          @@logger.info('MedusaIngester.sync_collections(): '\
              "deleting #{col.title} (#{col.repository_id})")
          col.destroy!
        end
      end
    end
  end

  ##
  # Creates new DLS items for any Medusa items that do not already exist in
  # the DLS.
  #
  # @param collection [Collection]
  # @param sync_mode [Symbol] Value of one of the IngestMode constants.
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
  def sync_items(collection, sync_mode, options = {}, task = nil)
    case sync_mode.to_sym
      when IngestMode::CREATE_ONLY
        self.create_items(collection, options, task)
      when IngestMode::DELETE_MISSING
        self.delete_missing_items(collection, task)
      when IngestMode::REPLACE_METADATA
        self.replace_metadata(collection, task)
      when IngestMode::UPDATE_BINARIES
        self.update_binaries(collection, task)
      else
        raise ArgumentError, "Unknown sync mode: #{sync_mode}"
    end
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
    ingester_for(collection).update_binaries(collection, task)
  end

  private

  ##
  # @param collection [Collection]
  # @raises [ArgumentError] If the collection's file group or package profile
  #                         are not set or invalid.
  #
  def ingester_for(collection)
    case collection.package_profile
      when PackageProfile::COMPOUND_OBJECT_PROFILE
        ingester = MedusaCompoundObjectIngester.new
      when PackageProfile::FREE_FORM_PROFILE
        ingester = MedusaFreeFormIngester.new
      when PackageProfile::MIXED_MEDIA_PROFILE
        ingester = MedusaMixedMediaIngester.new
      when PackageProfile::SINGLE_ITEM_OBJECT_PROFILE
        ingester = MedusaSingleItemIngester.new
      else
        raise ArgumentError,
              "Unrecognized package profile for collection #{collection}."
    end
    ingester
  end

end
