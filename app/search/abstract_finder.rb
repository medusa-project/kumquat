class AbstractFinder

  def initialize
    @aggregations = true
    @bucket_limit = Option::integer(Option::Keys::FACET_TERM_LIMIT)
    @filters = {} # Hash<String,Object>
    @limit = ElasticsearchClient::MAX_RESULT_WINDOW
    @orders = [] # Array<Hash<Symbol,String>> with :field and :direction keys
    @query = nil # Hash<Symbol,String> Hash with :field and :query keys
    @start = 0
    @user_roles = []

    @loaded = false

    @result_count = 0
    @result_facets = []
    @result_instances = []
    @result_suggestions = []
  end

  ##
  # @param boolean [Boolean] Whether to compile aggregations (for faceting) in
  #                          results. Disabling these when they are not needed
  #                          may improve performance.
  # @return [self]
  #
  def aggregations(boolean)
    @aggregations = boolean
    self
  end

  ##
  # @return [Integer]
  #
  def count
    load
    @result_count
  end

  ##
  # @param filters [Enumerable<String>, Hash<String,Object>, String] Enumerable
  #                of strings with colon-separated fields and values; hash of
  #                fields and values; or a colon-separated field/value string.
  # @return [self]
  #
  def facet_filters(filters)
    if filters.present?
      if filters.respond_to?(:keys) # check if it's a hash
        @filters = filters
      elsif filters.respond_to?(:each) # check if it's an Enumerable
        filters.each do |filter|
          add_facet_filter_string(filter)
        end
      else
        add_facet_filter_string(filters)
      end
    end
    self
  end

  ##
  # @param limit [Integer] Maximum number of buckets that will be returned in a
  #                        facet.
  # @return [self]
  #
  def bucket_limit(limit)
    @bucket_limit = limit
  end

  ##
  # @return [Enumerable<Facet>] Result facets.
  #
  def facets
    load
    @result_facets
  end

  ##
  # Adds an arbitrary filter to limit results to.
  #
  # @param field [String]
  # @param value [Object] Single value or an array of "OR" values.
  # @return [self]
  #
  def filter(field, value)
    @filters.merge!({ field => value })
    self
  end

  ##
  # @return [Integer]
  #
  def get_limit
    @limit
  end

  ##
  # @return [Integer]
  #
  def get_start
    @start
  end

  ##
  # @param limit [Integer]
  # @return [self]
  #
  def limit(limit)
    @limit = limit.to_i
    self
  end

  ##
  # @param orders [Enumerable<String>, Enumerable<Hash<String,Symbol>>]
  #               Enumerable of string field names and/or hashes with field
  #               name => direction pairs (`:asc` or `:desc`).
  # @return [self]
  #
  def order(orders)
    @orders = [] # reset them
    if orders.respond_to?(:keys)
      @orders << { field: orders.keys.first,
                   direction: orders[orders.keys.first] }
    else
      @orders << { field: orders.to_s, direction: :asc }
    end
    self
  end

  ##
  # @return [Integer]
  #
  def page
    ((@start / @limit.to_f).ceil + 1 if @limit > 0) || 1
  end

  ##
  # Adds a query to search a particular field.
  #
  # @param field [String, Symbol] Field name
  # @param query [String]
  # @return [self]
  #
  def query(field, query)
    @query = { field: field.to_s, query: query.to_s } if query.present?
    self
  end

  ##
  # Adds a query to search all fields.
  #
  # @param query [String]
  # @return [self]
  #
  def query_all(query)
    query('_all', query)
    self
  end

  ##
  # @param start [Integer]
  # @return [self]
  #
  def start(start)
    @start = start.to_i
    self
  end

  ##
  # @return [Enumerable<String>] Result suggestions.
  #
  def suggestions
    [] # TODO: write this
  end

  ##
  # @return [Enumerable<Item>]
  #
  def to_a
    load
    @result_instances
  end

  ##
  # @param roles [Enumerable<Role>, Enumerable<String>]
  # @return [self]
  #
  def user_roles(roles)
    @user_roles = roles.map { |r| r.kind_of?(Role) ? r.key : r }
    self
  end

  protected

  def add_facet_filter_string(str)
    parts = str.split(':')
    if parts.length == 2
      @filters[parts[0]] = parts[1]
    end
  end

  ##
  # @return [Elasticsearch::Model::Response::Response] Return value of
  #                                                    ?.__elasticsearch__.search
  #
  def get_response
    raise 'Must override get_response()'
  end

  def load
    return if @loaded

    response = get_response

    # Assemble the response aggregations into Facets.
    response.response.aggregations&.each do |agg|
      element = metadata_profile.facet_elements.
          select{ |e| e.indexed_keyword_field == agg[0] }.first
      if element
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

    @result_instances = response.records
    @result_count = response.results.total

    @loaded = true
  end

end