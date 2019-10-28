##
# Provides a convenient ActiveRecord-style Builder interface for Item retrieval.
#
class ItemFinder < AbstractFinder

  LOGGER = CustomLogger.new(ItemFinder)
  BYTE_SIZE_AGGREGATION = 'byte_size'

  def initialize
    super
    @collection = nil
    @exclude_variants = []
    @include_children_in_results = false
    @include_unpublished = false
    @include_variants = []
    @item_set = nil
    @only_described = false
    @parent_item = nil
    @search_children = false

    @result_byte_size = 0
  end

  ##
  # @param collection [Collection]
  # @return [ItemFinder] self
  #
  def collection(collection)
    @collection = collection
    self
  end

  ##
  # @param variants [String] One or more `Item::Variants` constant values.
  # @return [ItemFinder] self
  #
  def exclude_variants(*variants)
    @exclude_variants = variants
    self
  end

  ##
  # @param bool [Boolean] Whether to include children (even unmatching ones) in
  #                       results. Ordering by `Item::Variants::STRUCTURAL_SORT`
  #                       would then achieve a "flat tree" of results.
  # @return [ItemFinder] self
  # @see search_children()
  #
  def include_children_in_results(bool)
    @include_children_in_results = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [ItemFinder] self
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param variants [String] One or more Item::Variants constant values.
  # @return [ItemFinder] self
  #
  def include_variants(*variants)
    @include_variants = variants
    self
  end

  ##
  # @param item_set [ItemSet] Limit results to items within this ItemSet.
  # @return [ItemFinder] self
  #
  def item_set(item_set)
    @item_set = item_set
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [ItemFinder] self
  #
  def only_described(boolean)
    @only_described = boolean
    self
  end

  ##
  # @param parent_item [Item]
  # @return [ItemFinder] self
  #
  def parent_item(item)
    @parent_item = item
    self
  end

  ##
  # @param bool [Boolean] Whether to search and include matching children in
  #                       results. If false, child items (items with a non-nil
  #                       parent ID) will be excluded.
  # @return [ItemFinder] self
  # @see include_children_in_results()
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @return [Enumerable<Item>]
  #
  def to_a
    items = to_id_a.map do |id|
      it = Item.find_by_repository_id(id)
      LOGGER.debug("to_a(): #{id} is missing from the database") unless it
      it
    end
    items.select(&:present?)
  end

  ##
  # @return [Enumerable<String>] Enumerable of Item repository IDs.
  #
  def to_id_a
    load
    @response['hits']['hits']
        .map{ |r| r['_source'][Item::IndexFields::REPOSITORY_ID] }
  end

  ##
  # For this to work, `stats()` must have been called with an argument of
  # `true`.
  #
  # @return [Integer]
  #
  def total_byte_size
    load
    @result_byte_size
  end

  protected

  def get_response
    index = ElasticsearchIndex.current_index(Item::ELASTICSEARCH_INDEX)
    result = @client.query(index.name, build_query)
    JSON.parse(result)
  end

  def load
    return if @loaded

    @response = get_response

    # Assemble the response aggregations into Facets. The order of the facets
    # should be the same as the order of elements in the metadata profile.
    metadata_profile.facet_elements.each do |element|
      agg = @response['aggregations']&.
          find{ |a| a[0] == element.indexed_keyword_field }
      if agg
        facet = Facet.new
        facet.name = element.label
        facet.field = element.indexed_keyword_field
        agg[1]['buckets'].each do |bucket|
          term = FacetTerm.new
          term.name = bucket['key'].to_s
          term.label = bucket['key'].to_s
          term.count = bucket['doc_count']
          term.facet = facet
          facet.terms << term
        end
        @result_facets << facet
      end
    end

    agg = @response['aggregations']&.find{ |a| a[0] == BYTE_SIZE_AGGREGATION }
    if agg
      @result_byte_size = agg[1]['value'].to_i
    end

    if @response['hits']
      @result_count = @response['hits']['total']
    else
      @result_count = 0
      raise IOError, "#{@response['error']['type']}: #{@response['error']['root_cause'][0]['reason']}"
    end

    @loaded = true
  end

  def metadata_profile
    @collection&.effective_metadata_profile || MetadataProfile.default
  end

  private

  ##
  # @return [String] JSON string.
  #
  def build_query
    json = Jbuilder.encode do |j|
      j.query do
        j.bool do
          # Query
          if @query.present?
            j.must do
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.query_string do
                j.query sanitized_query
                j.default_operator 'AND'
                j.lenient true
                if @include_children_in_results
                  j.fields [@query[:field],
                            ItemElement.new(name: EntityElement.element_name_for_indexed_field(@query[:field])).parent_indexed_field]
                else
                  j.default_field @query[:field]
                end
              end
            end
          end

          if @filters.any? or @item_set or @parent_item or @collection or
              @only_described or !@include_unpublished
            j.filter do
              @filters.each do |field, value|
                j.child! do
                  if value.respond_to?(:each)
                    j.terms do
                      j.set! field, value
                    end
                  else
                    j.term do
                      j.set! field, value
                    end
                  end
                end
              end

              if @item_set
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::ITEM_SETS, @item_set.id
                  end
                end
              end

              if @parent_item
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::PARENT_ITEM,
                           @parent_item.repository_id
                  end
                end
              end

              if @collection
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::COLLECTION,
                           @collection.repository_id
                  end
                end
              end

              if @only_described
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::DESCRIBED, true
                  end
                end
              end

              unless @include_unpublished
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::PUBLICLY_ACCESSIBLE, true
                  end
                end
              end
            end
          end

          if @user_roles.any? or @include_variants.any?
            j.should do
              if @user_roles.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_ALLOWED_ROLES,
                           @user_roles
                  end
                end
                j.child! do
                  j.range do
                    j.set! Item::IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT do
                      j.lte 0
                    end
                  end
                end
              end

              if @include_variants.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::VARIANT, @include_variants
                  end
                end
              end
            end
            j.minimum_should_match 1
          end

          if @user_roles.any? or @exclude_variants.any? or !@search_children
            j.must_not do
              if @user_roles.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_DENIED_ROLES,
                           @user_roles
                  end
                end
              end

              if @exclude_variants.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::VARIANT, @exclude_variants
                  end
                end
              end

              if !@include_children_in_results and !@search_children
                j.child! do
                  j.exists do
                    j.field Item::IndexFields::PARENT_ITEM
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      j.aggregations do
        if @aggregations
          # Facetable elements in the metadata profile
          metadata_profile.facet_elements.each do |field|
            j.set! field.indexed_keyword_field do
              j.terms do
                j.field field.indexed_keyword_field
                j.size @bucket_limit
              end
            end
          end
        end

        # Total byte size
        j.set! BYTE_SIZE_AGGREGATION do
          j.sum do
            j.field Item::IndexFields::TOTAL_BYTE_SIZE
          end
        end
      end

      # Ordering
      # Order by explicit orders, if provided; otherwise sort by the metadata
      # profile's default order, if @orders is set to true; otherwise don't
      # sort.
      if @orders.respond_to?(:any?) and @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
              j.unmapped_type 'keyword'
            end
          end
        end
      elsif @orders
        el = metadata_profile.default_sortable_element
        if el
          j.sort do
            j.set! el.indexed_sort_field, 'asc'
          end
        end
      end

      # Start
      if @start.present?
        j.from @start
      end

      # Limit
      if @limit.present?
        j.size @limit
      end
    end

    # For debugging
    #File.write('query.json', JSON.pretty_generate(JSON.parse(json)))
    # curl -XGET 'localhost:9200/items_development/_search?size=0&pretty' -H 'Content-Type: application/json' -d @query.json

    json
  end

end