class SpecialCollectionSearch
  
  attr_reader :search_query, :collections, :items, :facets
  
  ##
  # @param query [String] Search query string
  # @param start [Integer] Starting position for pagination
  # @param limit [Integer] Number of results per page
  # @param facet_filters [Array] Facet filters to apply
  #
  def initialize(query: nil, start: 0, limit: 40, facet_filters: [])
    @search_query = query
    @start = start
    @limit = limit
    @facet_filters = facet_filters || []
    
    @collections = []
    @items = []
    @facets = []
    @total_count = 0
  end

  ##
  # Executes the search and populates results
  #
  def execute!
    # Search collections
    collection_search = SimpleCollectionSearch.new(query: @search_query)
    collection_search.facet_filters(@facet_filters)
    collection_search.start(@start).limit(@limit)
    collection_search.aggregations(true)
    
    @collections = collection_search.results
    @collection_count = collection_search.count
    @facets = collection_search.facets
    
    # Search items  
    item_search = SimpleItemSearch.new(query: @search_query)
    item_search.facet_filters(@facet_filters)
    item_search.start(@start).limit(@limit)
    
    @items = item_search.results
    @item_count = item_search.count
    
    # Combine and sort results by relevance
    # This is a simplified approach - you may want more sophisticated merging
    @combined_results = combine_and_sort_results
    
    self
  end
  
  def count
    @collection_count + @item_count
  end
  
  def collection_count
    @collection_count || 0
  end
  
  def item_count  
    @item_count || 0
  end
  
  def results
    @combined_results || []
  end

  private
  
  def combine_and_sort_results
    # Simple approach: show collections first, then items
    # You could implement more sophisticated relevance scoring here
    results = []
    
    # Add collections with type indicator
    @collections.each do |collection|
      results << {
        type: 'collection',
        object: collection,
        title: collection.title,
        creator: collection.element(:creator),
        description: collection.element(:description)
      }
    end
    
    # Add items with type indicator  
    @items.each do |item|
      results << {
        type: 'item', 
        object: item,
        title: item.title,
        creator: item.element(:creator),
        description: item.element(:description),
        collection: item.collection
      }
    end
    
    # Limit to the requested page size
    results.take(@limit)
  end

end