##
# Provides a convenient ActiveRecord-style Builder interface for Collection
# retrieval.
#
class CollectionRelation < AbstractRelation

  LOGGER = CustomLogger.new(CollectionRelation)

  def initialize
    super
    @include_restricted  = false
    @include_unpublished = false
    @parent_collection   = nil
    @search_children     = false
  end

  ##
  # @param bool [Boolean]
  # @return [CollectionRelation] The instance.
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [CollectionRelation] The instance.
  #
  def include_restricted(bool)
    @include_restricted = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [CollectionRelation] The instance.
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param collection [Collection]
  # @return [CollectionRelation] The instance.
  #
  def parent_collection(collection)
    @parent_collection = collection
    self
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def to_a
    load
    # This is basically a "WHERE IN" query that preserves the order of the
    # results corresponding to the IDs in the "IN" clause.
    # TODO: monkey-patch ActiveRecord::Base?
    sql_arr = to_id_a.map{ |e| "\"#{e}\"" }.join(',')
    Collection.joins("JOIN unnest('{#{sql_arr}}'::text[]) WITH ORDINALITY t(repository_id, ord) USING (repository_id)").
      order('t.ord')
  end

  def to_id_a
    load
    @response_json['hits']['hits']
      .map { |r| r['_source'][Collection::IndexFields::REPOSITORY_ID] }
  end


  protected

  def get_response
    result = @client.query(build_query)
    JSON.parse(result)
  end


  private

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
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
              j.simple_query_string do
                j.query @query[:query]
                j.fields [@query[:field]]
                j.flags 'NONE'
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

            unless @include_restricted
              j.child! do
                j.term do
                  j.set! Collection::IndexFields::RESTRICTED, false
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

          unless @search_children
            j.must_not do
              j.child! do
                j.exists do
                  j.field Collection::IndexFields::PARENT_COLLECTIONS
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
                j.size OpensearchClient::AGGREGATION_BUCKET_LIMIT
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
              j.unmapped_type 'keyword'
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