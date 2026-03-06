class SimpleItemSearch < ItemRelation 
  
  attr_reader :search_query

  ##
  # @param query [String] Search query string
  # @param dls_only [Boolean] Limit to DLS items only (default: true)
  #
  def initialize(query: nil, dls_only: true)
    super()
    @search_query = query
    @dls_only = dls_only

    apply_filters
  end

  ##
  # @return [Enumerable<Item>]
  #
  def results
    to_a
  end

  private

  def apply_filters
    # Note: include_unpublished(false) already filters to published items,
    # so we don't need the redundant filter() call here
    
    include_unpublished(false)
    include_restricted(false)
    include_publicly_inaccessible(false)

    if @search_query.present?
      query_all(@search_query)
    else
      # Default ordering when no query
      order(Item::IndexFields::TITLE)
    end
  end

end