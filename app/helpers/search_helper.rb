module SearchHelper

  ##
  # Returns the total count of available searchable items in Digital Special Collections
  # This includes both collections and individual items that are published and unrestricted
  #
  # @return [Integer] Total count of searchable collections + items
  #
  def total_available_dls_count
    Rails.cache.fetch('dls_total_count', expires_in: 1.hour) do
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
  rescue => e
    Rails.logger.error "Error fetching DLS total count: #{e.message}"
    # Return a fallback count to prevent page failures
    0
  end

end