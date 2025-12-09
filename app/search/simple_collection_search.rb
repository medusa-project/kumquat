class SimpleCollectionSearch < CollectionRelation

  attr_reader :search_query

  ##
  # @param query [String] Search query string
  # @param dls_only [Boolean] Limit to DLS collections only (default: true)
  #
  def initialize(query: nil, dls_only: true)
    super()
    @search_query = query
    @dls_only = dls_only

    apply_filters
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def results
    to_a
  end

  private

  def apply_filters
    if @dls_only
      filter(Collection::IndexFields::PUBLISHED_IN_DLS, true)
    end

    include_unpublished(false)
    include_restricted(false)

    if @search_query.present?
      query_all(@search_query)
    else
      order(Collection::IndexFields::REPOSITORY_TITLE)
    end
  end

end