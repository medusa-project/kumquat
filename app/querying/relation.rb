##
# Query builder class, conceptually similar to [ActiveRecord::Relation].
#
class Relation

  # @!attribute solr_response
  #   @return [Hash]
  attr_reader :solr_response

  ##
  # @param caller [Object<SolrQuerying>] The calling entity, or `nil` to
  # initialize an "empty query", i.e. one that will return no results.
  #
  def initialize(caller = nil)
    @caller = caller
    @calling_class = caller.kind_of?(Class) ? caller : caller.class
    @facet = true
    @facetable_fields = []
    @facet_queries = []
    @filter_clauses = [] # will be joined by AND
    @limit = 1 # default to fastest; clients can override with limit(int)
    @more_like_this = false
    @omit_entity_query = false
    @order = nil
    @start = 0
    @where_clauses = [] # will be joined by AND
    reset_results
  end

  def all
    reset_results
    self
  end

  ##
  # @return [Integer]
  #
  def count
    self.to_a.total_length
  end

  ##
  # @param fq [Array, String]
  # @return [Relation] self
  #
  def facet(fq)
    reset_results
    if fq === false
      @facet = false
    elsif fq.blank?
      # noop
    elsif fq.respond_to?(:each)
      @facet_queries += fq.reject{ |v| v.blank? }
    elsif fq.respond_to?(:to_s)
      @facet_queries << fq.to_s
    end
    self
  end

  ##
  # @param fields [Array]
  # @return [self, Array]
  #
  def facetable_fields(fields = nil)
    if fields
      @facetable_fields =
          [Item::SolrFields::COLLECTION + ItemElement.solr_facet_suffix] + fields
      return self
    end
    @facetable_fields
  end

  ##
  # @param fq [Hash, String]
  # @return [Relation] self
  #
  def filter(fq)
    reset_results
    if fq.blank?
      # noop
    elsif fq.kind_of?(Hash)
      fq = fq.reject{ |k, v| k.blank? or v.blank? }
      @filter_clauses += fq.map do |k, v|
        if v == :null
          "-#{k}:[* TO *]"
        elsif v == :not_null
          "#{k}:[* TO *]"
        else
          "#{k}:#{['(', '['].include?(v.to_s[0]) ? v : "\"#{v}\""}"
        end
      end
    elsif fq.respond_to?(:to_s)
      @filter_clauses << fq.to_s
    end
    self
  end

  def find_each(options = {})
    limit = 100
    page = 1
    loop do
      offset = (page - 1) * limit
      batch = self.limit(limit).start(offset)
      page += 1

      Rails.logger.debug("Relation.find_each(): limit: #{limit} | offset: #{offset}")

      batch.select{ |x| x }.each{ |x| yield x }

      break if batch.size < limit
    end
  end

  ##
  # @return [Object<SolrQuerying>, nil]
  #
  def first
    @limit = 1
    self.to_a.first
  end

  ##
  # @param limit [Integer]
  # @return [Relation] self
  #
  def limit(limit)
    reset_results
    @limit = limit
    self
  end

  def method_missing(name, *args, &block)
    if @results.respond_to?(name)
      self.to_a.send(name, *args, &block)
    else
      super
    end
  end

  ##
  # Activates a "more like this" query.
  #
  # @return [Relation] self
  #
  def more_like_this
    raise 'Caller is not set.' unless @caller
    reset_results
    @more_like_this = true
    @facet = false
    self.where(PearTree::Application.peartree_config[:solr_id_field] => @caller.id)
  end

  def none
    Relation.new
  end

  ##
  # Whether to omit the entity query from the Solr query. If false, calling
  # something like `MyEntity.where(..)` will automatically limit the query to
  # results of `MyEntity` type.
  #
  # The entity query is present by default.
  #
  # @param boolean [Boolean]
  # @return [Relation] self
  #
  def omit_entity_query(boolean)
    @omit_entity_query = boolean
    self
  end

  ##
  # @param order [Hash, String, Symbol] Supply :random to sort randomly.
  # @return [Relation] self
  #
  def order(order)
    reset_results
    if order.kind_of?(Symbol) and order == :random
      order = "random_#{SecureRandom.hex} asc"
    elsif order.kind_of?(Hash)
      order = order.map{ |k, v| "#{k} #{v}" }.join(', ')
    else
      order = order.to_s
      order += ' asc' if !order.end_with?(' asc') and
          !order.end_with?(' desc')
    end
    @order = order
    self
  end

  def respond_to_missing?(method_name, include_private = false)
    @results.respond_to?(method_name) || super
  end

  ##
  # @param start [Integer]
  # @return [Relation] self
  #
  def start(start)
    reset_results
    @start = start
    self
  end

  ##
  # Search using a string:
  #
  # where('solr_field:"value"')
  #
  # Search using a hash:
  #
  # where('solr_field' => 'value')
  #
  # Search for null:
  #
  # where('solr_field' => :null)
  #
  # Search for not-null:
  #
  # where('solr_field' => :not_null)
  #
  # @param where [Hash, String]
  # @return [Relation] self
  #
  def where(where)
    reset_results
    if where.blank?
      # noop
    elsif where.kind_of?(Hash)
      where = where.reject{ |k, v| k.blank? or v.blank? }
      @where_clauses += where.map do |k, v|
        if v == :null
          "-#{k}:[* TO *]"
        elsif v == :not_null
          "#{k}:[* TO *]"
        else
          "#{k}:#{['(', '['].include?(v.to_s[0]) ? v : "\"#{v}\""}"
        end
      end
    elsif where.respond_to?(:to_s)
      @where_clauses << where.to_s
    end
    self
  end

  ##
  # @return [ResultSet]
  #
  def to_a
    load
    @results
  end

  private

  def load
    if @caller and @calling_class and !@loaded
      if !@omit_entity_query
        # limit the query to the calling class
        @where_clauses << "#{PearTree::Application.peartree_config[:solr_class_field]}:\""\
        "#{@calling_class}\""
      end
      params = {
          'q' => @where_clauses.join(' AND '),
          'df' => PearTree::Application.peartree_config[:solr_default_search_field],
          'fl' => @calling_class::SolrFields::ID,
          'fq' => @filter_clauses.join(' AND '),
          'start' => @start,
          'sort' => @order,
          'rows' => @limit.to_i > 0 ? @limit.to_i : 99999
      }
      if @more_like_this
        params['mlt.fl'] = PearTree::Application.peartree_config[:solr_default_search_field]
        params['mlt.mindf'] = 1
        params['mlt.mintf'] = 1
        params['mlt.match.include'] = false
        params['fq'] = "#{PearTree::Application.peartree_config[:solr_class_field]}:\""\
        "#{@calling_class}\""
        endpoint = PearTree::Application.peartree_config[:solr_more_like_this_endpoint].gsub(/\//, '')
      else
        endpoint = 'select'
        if @facet and self.facetable_fields.any?
          params['facet'] = true
          params['facet.mincount'] = 1
          params['facet.field'] = self.facetable_fields
          params['fq'] = @facet_queries
        end
      end

      @solr_response = Solr.instance.get(endpoint, params: params)

      Rails.logger.debug("Solr response:\n#{@solr_response}")

      if !@more_like_this and @solr_response['facet_counts']
        @results.facet_fields = solr_facet_fields_to_objects(
            @solr_response['facet_counts']['facet_fields'])
      end
      @results.total_length = @solr_response['response']['numFound'].to_i
      docs = @solr_response['response']['docs']
      docs.each do |doc|
        begin
          # Find the database entity corresponding to the Solr document ID,
          # and add it to the results. If it doesn't exist, add its ID rather
          # than nil.
          entity = @calling_class.
              find_by_repository_id(doc[@calling_class::SolrFields::ID])
          @results << entity || doc[@calling_class::SolrFields::ID]
        rescue => e
          Rails.logger.error("#{e} (#{doc['id']}) (#{e.backtrace})")
          @results.total_length -= 1
        end
      end
      @loaded = true
    end
  end

  ##
  # Reverts the instance to an "un-executed" state.
  #
  def reset_results
    @loaded = false
    @results = ResultSet.new
    @solr_response = nil
  end

  def solr_facet_fields_to_objects(fields)
    facets = []
    fields.each do |field, terms|
      facet = Facet.new
      facet.field = field
      (0..terms.length - 1).step(2) do |i|
        term = Facet::Term.new
        term.name = terms[i]
        term.label = terms[i]
        term.count = terms[i + 1]
        term.facet = facet
        facet.terms << term
      end
      facets << facet
    end
    facets
  end

end
