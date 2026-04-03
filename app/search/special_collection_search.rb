class SpecialCollectionSearch
  
  attr_reader :search_query, :collections, :items, :facets
  
  ##
  # @param query [String] Search query string
  # @param start [Integer] Starting position for pagination
  # @param limit [Integer] Number of results per page
  # @param facet_filters [Array] Facet filters to apply
  # @param repository_id [Integer] Optional repository ID to scope search to specific repository
  #
  def initialize(query: nil, start: 0, limit: 40, facet_filters: [], repository_id: nil)
    @search_query = query
    @start = start
    @limit = limit
    @facet_filters = facet_filters || []
    @repository_id = repository_id
    
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
    
    # Apply repository filtering if specified (optimized to avoid duplicate lookups)
    repository_collection_ids = []
    if @repository_id
      begin
        # Single database query to get collection IDs for this repository
        repository_collection_ids = get_collection_ids_for_repository(@repository_id)
        
        if repository_collection_ids.any?
          # Get repository title for collection filtering (only if we have collections)
          repository = Medusa::Repository.with_id(@repository_id)
          if repository
            collection_search.filter(Collection::IndexFields::REPOSITORY_TITLE, repository.title)
          end
        end
      rescue => e
        Rails.logger.warn("Could not fetch repository for search filtering: #{e.message}")
        # Continue without repository filtering if we can't fetch the repository
      end
    end
    
    @collections = collection_search.results
    @collection_count = collection_search.count
    
    # Search items  
    item_search = SimpleItemSearch.new(query: @search_query)
    item_search.facet_filters(@facet_filters)
    item_search.start(@start).limit(@limit)
    item_search.aggregations(true)
    
    # Apply repository filtering using already-fetched collection IDs
    if @repository_id && repository_collection_ids.any?
      # Use the collection IDs we already fetched
      item_search.filter(Item::IndexFields::COLLECTION, repository_collection_ids)
    elsif @repository_id
      # No collections in this repository, so no items either
      item_search.filter(Item::IndexFields::COLLECTION, ['__no_match__'])
    end
    
    @items = item_search.results
    @item_count = item_search.count
    
    # Merge facets from both searches
    collection_facets = collection_search.facets || []
    item_facets = item_search.facets || []
    @facets = merge_facets(collection_facets, item_facets)
    
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
  
  ##
  # Gets all collection repository IDs that belong to the specified repository
  # @param repository_id [Integer] The repository ID
  # @return [Array<String>] Array of collection repository IDs
  #
  def get_collection_ids_for_repository(repository_id)
    Collection.where(medusa_repository_id: repository_id,
                     public_in_medusa: true,
                     published_in_dls: true)
              .pluck(:repository_id)
  end

  def merge_facets(collection_facets, item_facets)
    # If no item facets, just return collection facets
    return collection_facets if item_facets.nil? || item_facets.empty?
    # If no collection facets, just return item facets  
    return item_facets if collection_facets.nil? || collection_facets.empty?
    
    merged = {}
    
    # Process collection facets
    collection_facets.each do |facet|
      merged[facet.field] = {
        name: facet.name,
        field: facet.field,
        terms: {}
      }
      facet.terms.each do |term|
        merged[facet.field][:terms][term.name] = term.count
      end
    end
    
    # Add item facets, merging counts for matching terms
    item_facets.each do |facet|
      if merged[facet.field]
        # Merge with existing facet
        facet.terms.each do |term|
          if merged[facet.field][:terms][term.name]
            merged[facet.field][:terms][term.name] += term.count
          else
            merged[facet.field][:terms][term.name] = term.count
          end
        end
      else
        # New facet from items only
        merged[facet.field] = {
          name: facet.name,
          field: facet.field,
          terms: {}
        }
        facet.terms.each do |term|
          merged[facet.field][:terms][term.name] = term.count
        end
      end
    end
    
    # Convert back to Facet objects
    result_facets = []
    merged.each do |field, facet_data|
      facet = Facet.new
      facet.name = facet_data[:name]
      facet.field = facet_data[:field]
      
      facet_data[:terms].each do |term_name, count|
        term = FacetTerm.new
        term.name = term_name
        term.label = term_name
        term.count = count
        term.facet = facet
        facet.terms << term
      end
      
      # Sort terms by count descending
      facet.terms.sort_by! { |term| -term.count }
      result_facets << facet
    end
    
    result_facets
  end

end