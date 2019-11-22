##
# Provides a convenient ActiveRecord-style Builder interface for Collection
# retrieval.
#
class CollectionFinder < AbstractFinder

  LOGGER = CustomLogger.new(CollectionFinder)

  def initialize
    super
    @include_unpublished = false
    @parent_collection   = nil
    @search_children     = false
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param collection [Collection]
  # @return [self]
  #
  def parent_collection(collection)
    @parent_collection = collection
    self
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def to_a
    cols = to_id_a.map do |id|
      col = Collection.find_by_repository_id(id)
      LOGGER.debug("to_a(): #{id} is missing from the database") unless col
      col
    end
    cols.select(&:present?)
  end

  ##
  # @return [Enumerable<String>] Enumerable of repository IDs.
  #
  def to_id_a
    load
    @response['hits']['hits']
        .map { |r| r['_source'][Collection::IndexFields::REPOSITORY_ID] }
  end

  protected

  def metadata_profile
    MetadataProfile.default
  end

  def get_response
    result = @client.query(build_query)
    JSON.parse(result)
  end

  private

  def load
    return if @loaded

    @response = get_response

    # Assemble the response aggregations into Facets.
    @response['aggregations']&.each do |agg|
      facet = Facet.new
      facet.name = Collection.facet_fields.select{ |f| f[:name] == agg[0] }.
          first[:label]
      facet.field = agg[0]
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

    if @response['hits']
      @result_count = @response['hits']['total'] # ES 6.x
      if @result_count.respond_to?(:keys)
        @result_count = @result_count['value'] # ES 7.x
      end
    else
      @result_count = 0
      raise IOError, "#{@response['error']['type']}: #{@response['error']['root_cause'][0]['reason']}"
    end

    @loaded = true
  end

  ##
  # @return [String] JSON string.
  #
  def build_query
    Jbuilder.encode do |j|
      j.track_total_hits true
      j.query do
        j.bool do
          # Query
          if @query.present?
            j.must do
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.query_string do
                j.query sanitized_query
                j.default_field @query[:field]
                j.default_operator 'AND'
                j.lenient true
              end
            end
          end

          j.filter do
            j.term do
              j.set! Collection::IndexFields::CLASS, 'Collection'
            end

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

            if @parent_collection
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::PARENT_COLLECTIONS,
                         @parent_collection.repository_id
                end
              end
            end

            unless @include_unpublished
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::PUBLICLY_ACCESSIBLE, true
                end
              end
            end
          end

          if @host_groups.any?
            j.should do
              j.child! do
                j.terms do
                  j.set! Collection::IndexFields::ALLOWED_HOST_GROUPS, @host_groups
                end
              end
              j.child! do
                j.range do
                  j.set! Collection::IndexFields::ALLOWED_HOST_GROUP_COUNT do
                    j.lte 0
                  end
                end
              end
            end
          end

          if @host_groups.any? or !@search_children
            j.must_not do
              if @host_groups.any?
                j.child! do
                  j.terms do
                    j.set! Collection::IndexFields::DENIED_HOST_GROUPS, @host_groups
                  end
                end
              end
              unless @search_children
                j.child! do
                  j.exists do
                    j.field Collection::IndexFields::PARENT_COLLECTIONS
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      if @aggregations
        j.aggregations do
          Collection.facet_fields.each do |facet|
            j.set! facet[:name] do
              j.terms do
                j.field facet[:name]
                j.size @bucket_limit
              end
            end
          end
        end
      end

      # Ordering
      if @orders&.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
            end
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
  end

end