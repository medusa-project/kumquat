class MedusaAbstractIngester

  LOGGER = CustomLogger.new(MedusaAbstractIngester)

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
      LOGGER.info('replace_metadata(): %s', item.repository_id)
      update_item_from_embedded_metadata(item)
      item.save!
      stats[:num_updated] += 1

      if task and index % 10 == 0
        task.update(percent_complete: index / num_items.to_f)
      end
    end
    stats
  end

  protected

  ##
  # @param collection [Collection]
  # @param package_profile [PackageProfile,nil] Package profile that the given
  #                                             collection is expected to have.
  #                                             Omit to skip this validation.
  # @raises [ArgumentError]
  #
  def check_collection(collection, package_profile = nil)
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection package profile is set incorrectly' if
        package_profile and collection.package_profile != package_profile
    raise ArgumentError, 'Collection\'s Medusa CFS directory is invalid' unless
        collection.effective_medusa_cfs_directory
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
