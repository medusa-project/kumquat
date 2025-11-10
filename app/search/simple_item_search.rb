##
# Provides simple keyword search across all item fields.
# Extends ItemRelation to work with Kumquat's OpenSearch schema.
#
# Usage:
#   search = SimpleItemSearch.new(query: "lincoln")
#   results = search.results
#   count = search.count
#
class SimpleItemSearch < ItemRelation

  attr_reader :search_query

  ##
  # @param query [String] Search query string
  # @param published_only [Boolean] Limit to published items (default: true)
  # @param accessible_only [Boolean] Limit to publicly accessible items (default: true)
  # @param dls_only [Boolean] Limit to DLS collections only (default: true)
  #
  def initialize(query: nil, published_only: true, accessible_only: true, dls_only: true)
    super()
    @search_query = query
    @published_only = published_only
    @accessible_only = accessible_only
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
    # Apply DLS collection filter if requested
    if @dls_only
      dls_collection_ids = Collection.where(published_in_dls: true).pluck(:repository_id)
      self.collections(dls_collection_ids) if dls_collection_ids.any?
    end

    # Apply published filter
    self.include_unpublished(!@published_only)

    # Apply accessibility filter
    self.include_publicly_inaccessible(!@accessible_only)
    self.include_restricted(false)

    # Apply search query if present
    if @search_query.present?
      # Use search_all field for simple keyword search
      self.query_all(@search_query)
      # When a query is present, OpenSearch automatically orders by relevance score
      # so we don't need to explicitly set ordering
    else
      # Use default metadata profile ordering when browsing (no query)
      self.order(true)
    end
  end

end
