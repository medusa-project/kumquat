module SearchHelper

  ##
  # Returns the total count of available searchable items in Digital Special Collections
  # This includes both collections and individual items that are published and unrestricted
  #
  # @return [Integer] Total count of searchable collections + items
  #
  def total_available_dls_count
    # Get total count of DLS collections
    collection_count = Collection.search
      .aggregations(false)
      .include_unpublished(false)
      .include_restricted(false) 
      .filter(Collection::IndexFields::PUBLISHED_IN_DLS, true)
      .count

    # Get total count of DLS items
    item_count = Item.search
      .aggregations(false)
      .include_unpublished(false)
      .include_restricted(false)
      .include_publicly_inaccessible(false)
      .filter(Item::IndexFields::PUBLISHED, true)
      .count

    collection_count + item_count
  end

end