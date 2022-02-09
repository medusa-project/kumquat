##
# Abstract base class for type-specific "relations," which are objects that
# simplify Elasticsearch queries (which can be pretty complex & awkward) using
# the Builder pattern, similar to {ActiveRecord::Relation}.
#
class AbstractRelation

  include Enumerable

  AGGREGATION_TERM_LIMIT = 100
  BYTE_SIZE_AGGREGATION  = 'byte_size'

  attr_reader :request_json, :response_json

  def initialize
    @client = ElasticsearchClient.instance

    @aggregations = true
    @bucket_limit = AGGREGATION_TERM_LIMIT
    @exact_match  = false
    @filters      = {} # Hash<String,Object>
    @host_groups  = []
    @limit        = ElasticsearchClient::MAX_RESULT_WINDOW
    @orders       = [] # Array<Hash<Symbol,String>> with :field and :direction keys
    @query        = nil # Hash<Symbol,String> Hash with :field and :query keys
    @start        = 0

    @loaded = false

    @request_json       = {}
    @response_json      = {}
    @result_byte_size   = 0
    @result_count       = 0
    @result_facets      = []
    @result_instances   = []
    @result_suggestions = []
  end

  ###########################################################################
  # BUILDER METHODS
  # These methods initialize the query.
  ###########################################################################

  ##
  # @param boolean [Boolean] Whether to compile aggregations (for faceting) in
  #                          results. Disabling these when they are not needed
  #                          may improve performance.
  # @return [self]
  #
  def aggregations(boolean)
    @aggregations = boolean
    @loaded = false
    self
  end

  ##
  # @param limit [Integer] Maximum number of buckets that will be returned in a
  #                        facet.
  # @return [self]
  #
  def bucket_limit(limit)
    @bucket_limit = limit
    @loaded = false
    self
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
      @loaded = false
    end
    self
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
    @loaded = false
    self
  end

  ##
  # Limits results to those accessible by any of the given {HostGroup}s or
  # {HostGroup#key host group keys}.
  #
  # @param host_groups [Enumerable<HostGroup>, Enumerable<String>]
  # @return [self]
  #
  def host_groups(host_groups)
    @host_groups = host_groups.map { |r| r.kind_of?(HostGroup) ? r.key : r }
    @loaded = false
    self
  end

  ##
  # @param limit [Integer]
  # @return [self]
  #
  def limit(limit)
    @limit = limit.to_i
    @loaded = false
    self
  end

  ##
  # @param orders [Enumerable<String>, Enumerable<Hash<String,Symbol>>, Boolean]
  #               Enumerable of string field names and/or hashes with field
  #               name => direction pairs (`:asc` or `:desc`). Supply false to
  #               disable ordering.
  # @return [self]
  #
  def order(orders)
    if orders
      @orders = [] # reset them
      if orders.respond_to?(:keys)
        @orders << { field: orders.keys.first,
                     direction: orders[orders.keys.first] }
      else
        @orders << { field: orders.to_s, direction: :asc }
      end
      @loaded = false
    else
      @orders = false
    end
    self
  end

  ##
  # Adds a query to search a particular field.
  #
  # @param field [String, Symbol] Field name
  # @param query [String]
  # @param exact_match [Boolean]
  # @return [self]
  #
  def query(field, query, exact_match = false)
    @query       = { field: field.to_s, query: query.to_s } if query.present?
    @exact_match = exact_match
    @loaded      = false
    self
  end

  ##
  # Adds a query to search all fields.
  #
  # @param query [String]
  # @return [self]
  #
  def query_all(query)
    query(ElasticsearchIndex::StandardFields::SEARCH_ALL, query)
    self
  end

  ##
  # @param start [Integer]
  # @return [self]
  #
  def start(start)
    @start = start.to_i
    @loaded = false
    self
  end

  ###########################################################################
  # RESULT METHODS
  # These methods retrieve results.
  ###########################################################################

  ##
  # @return [Integer]
  #
  def count
    load
    @result_count
  end

  ##
  # Required by the {Enumerable} contract.
  #
  def each(&block)
    to_a.each(&block)
  end

  ##
  # @return [Enumerable<Facet>] Result facets.
  #
  def facets
    load
    @result_facets
  end

  ##
  # @return [Integer] Limit provided to {limit}.
  #
  def get_limit
    @limit
  end

  ##
  # @return [Integer] Start provided to {start}.
  #
  def get_start
    @start
  end

  ##
  # @return [Integer]
  #
  def page
    ((@start / @limit.to_f).ceil + 1 if @limit > 0) || 1
  end

  ##
  # For this to work, {BYTE_SIZE_AGGREGATION} must have been included in the
  # query.
  #
  # @return [Integer]
  #
  def total_byte_size
    load
    @result_byte_size
  end

  ##
  # @return [Enumerable<String>] Result suggestions.
  #
  def suggestions
    [] # TODO: write this
  end

  ##
  # @return [Enumerable<?>]
  #
  def to_a
    raise 'Subclasses must override to_a() and map @response_json to an '\
        'Enumerable of model objects'
  end


  protected

  def add_facet_filter_string(str)
    parts = str.split(':')
    if parts.length == 2
      @filters[parts[0]] = parts[1]
    end
  end

  def get_response
    @request_json = build_query
    result = @client.query(@request_json)
    JSON.parse(result)
  end

  def metadata_profile
    MetadataProfile.default
  end

  def load
    return if @loaded

    @response_json = get_response

    # Assemble the response aggregations into Facets. The order of the facets
    # should be the same as the order of elements in the metadata profile.
    metadata_profile.facet_elements.each do |element|
      agg = @response_json['aggregations']&.
          find{ |a| a[0] == element.indexed_keyword_field }
      if agg
        facet       = Facet.new
        facet.name  = element.label
        facet.field = element.indexed_keyword_field
        agg[1]['buckets'].each do |bucket|
          term = FacetTerm.new
          term.name    = bucket['key'].to_s
          term.label   = bucket['key'].to_s
          term.count   = bucket['doc_count']
          term.facet   = facet
          facet.terms << term
        end
        @result_facets << facet
      end
    end

    agg = @response_json['aggregations']&.find{ |a| a[0] == BYTE_SIZE_AGGREGATION }
    if agg
      @result_byte_size = agg[1]['value'].to_i
    end

    if @response_json['hits']
      @result_count = @response_json['hits']['total'] # ES 6.x
      if @result_count.respond_to?(:keys)
        @result_count = @result_count['value'] # ES 7.x
      end
    elsif @response_json['error']
      @result_count = 0
      raise IOError, "#{@response_json['error']['type']}: "\
          "#{@response_json['error']['root_cause'][0]['reason']}"
    end

    @loaded = true
  end

end