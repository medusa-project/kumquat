# TODO
# Provides advanced field-specific search with boolean operators.
# Extends ItemRelation to work with Kumquat's OpenSearch schema.
#
# Usage:
#   search = AdvancedItemSearch.new(
#     criteria: [
#       { field: 'title', query: 'lincoln', operator: 'AND' },
#       { field: 'subject', query: 'president', operator: 'OR' }
#     ],
#     fuzzy: false
#   )
#   results = search.results
#   count = search.count
#
class AdvancedItemSearch < ItemRelation

#   # Map user-friendly field names to indexed field names
  SEARCHABLE_FIELDS = {
    'all_fields'   => OpensearchIndex::StandardFields::SEARCH_ALL,
    'title'        => ItemElement.new(name: 'title').indexed_field,
    'creator'      => ItemElement.new(name: 'creator').indexed_field,
    'contributor'  => ItemElement.new(name: 'contributor').indexed_field,
    'subject'      => ItemElement.new(name: 'subject').indexed_field,
    'description'  => ItemElement.new(name: 'description').indexed_field,
    'publisher'    => ItemElement.new(name: 'publisher').indexed_field,
    'date'         => ItemElement.new(name: 'date').indexed_field,
    'type'         => ItemElement.new(name: 'type').indexed_field,
    'format'       => ItemElement.new(name: 'format').indexed_field,
    'identifier'   => ItemElement.new(name: 'identifier').indexed_field,
    'source'       => ItemElement.new(name: 'source').indexed_field,
    'language'     => ItemElement.new(name: 'language').indexed_field,
    'relation'     => ItemElement.new(name: 'relation').indexed_field,
    'coverage'     => ItemElement.new(name: 'coverage').indexed_field,
    'rights'       => ItemElement.new(name: 'rights').indexed_field,
    'full_text'    => Item::IndexFields::FULL_TEXT
  }.freeze

  attr_reader :criteria

#   ##
#   # @param criteria [Array<Hash>] Array of search criteria hashes with keys:
#   #   - field: field name to search (see SEARCHABLE_FIELDS)
#   #   - query: search term
#   #   - operator: 'AND' or 'OR' (how to combine with previous criterion)
#   # TODO: @param fuzzy [Boolean] Enable fuzzy matching (default: false)
#   # @param published_only [Boolean] Limit to published items (default: true)
#   # @param accessible_only [Boolean] Limit to publicly accessible items (default: true)
#   # @param dls_only [Boolean] Limit to DLS collections only (default: true)
#   #
  def initialize(criteria:[], published_only: true, accessible_only: true, dls_only: true)
    super()
    @criteria = criteria 
    @published_only = published_only
    @accessible_only = accessible_only
    @dls_only = dls_only

    #TODO: Build the query here 
    # 
  end

##  # @return [Enumerable<Item>]
#
  def results 
    to_a 
  end

  ## @return [Hash] Map of user-friendly field names to indexed field names.
  #
  def self.searchable_fields
    SEARCHABLE_FIELDS.keys.map{|k| [k.titleize, k]}.to_h 
  end

  private 
  ## Applies filters for Advanced Item Search:
  # - DLS collections only (if requested)
  # - Published items only
  # - Publicly accessible items only
  # - Field-specific search criteria with boolean operators
  #
  def apply_filters
    if @dls_only
      dls_collection_ids = Collection.where(published_in_dls: true).pluck(:repository_id)
      collections(dls_collection_ids) if dls_collection_ids.any?
    end

    include_unpublished(!@published_only)

    include_publicly_inaccessible(!@accessible_only)
    include_restricted(false)

    #TODO: Apply search criteria 
  end
end
