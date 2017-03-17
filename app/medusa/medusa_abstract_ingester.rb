class MedusaAbstractIngester

  protected

  ##
  # @param collection [Collection]
  # @param package_profile [PackageProfile] Package profile that the given
  #                                         collection is expected to have.
  # @raises [ArgumentError]
  #
  def check_collection(collection, package_profile)
    raise ArgumentError, 'Collection file group is not set' unless
        collection.medusa_file_group
    raise ArgumentError, 'Collection package profile is not set' unless
        collection.package_profile
    raise ArgumentError, 'Collection package profile is set incorrectly' unless
        collection.package_profile == package_profile
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