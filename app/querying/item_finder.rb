##
# Provides a high-level item query interface using the Builder pattern.
#
class ItemFinder

  def initialize
    @include_children = false
    @include_unpublished = false
    @start = 0
    @limit = 999999
  end

  ##
  # @param hostname [String]
  # @return [self]
  #
  def client_hostname(hostname)
    @client_hostname = hostname
    self
  end

  ##
  # @param string [String]
  # @return [self]
  #
  def client_ip(string)
    @client_ip = string
    self
  end

  ##
  # @param user [User]
  # @return [self]
  #
  def client_user(user)
    @client_user = user
    self
  end

  ##
  # @param collection_id [Integer]
  # @return [self]
  #
  def collection_id(collection_id)
    @collection_id = collection_id
    self
  end

  ##
  # @return [Integer]
  #
  def count
    load
    @items.count
  end

  ##
  # @return [MetadataProfile]
  #
  def effective_metadata_profile
    @collection ? @collection.effective_metadata_profile :
        MetadataProfile.find_by_default(true)
  end

  ##
  # @param queries [Array]
  # @return [self]
  def facet_queries(queries)
    @facet_queries = queries
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [self]
  #
  def include_children(boolean)
    @include_children = boolean
    self
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
  # @return [Integer]
  #
  def page
    (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
  end

  ##
  # @param boolean [Boolean]
  # @return [self]
  def include_unpublished(boolean)
    @include_unpublished = boolean
    self
  end

  ##
  # @param string [String]
  # @return [self]
  #
  def query(string)
    @query = string
    self
  end

  ##
  # @param string [String]
  # @return [self]
  #
  def sort(string)
    @sort = string
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
  # @return [Array<String>]
  #
  def suggestions
    suggestions = []
    if @loaded and @query.present? and count < 1
      suggestions = Solr.instance.suggestions(@query)
    end
    suggestions
  end

  ##
  # @return [Enumerable<Item>]
  #
  def to_a
    load
    @items
  end

  private

  def load
    return if @loaded

    @items = Item.solr.all

    @items = @items.where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::COLLECTION_PUBLISHED => true) unless @include_unpublished
    @items = @items.where(@query) if @query

    role_keys = roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @items = @items.where("(#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:(#{role_keys.join(' ')}) "\
          "OR *:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *])")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @items = @items.where("-#{Item::SolrFields::EFFECTIVE_DENIED_ROLES}:(#{role_keys.join(' ')})")
    end

    @items = @items.where(Item::SolrFields::PARENT_ITEM => :null) unless @include_children

    if @facet_queries
      if @facet_queries.respond_to?(:each)
        @facet_queries.each { |fq| @items = @items.facet(fq) }
      else
        @items = @items.facet(params[:fq])
      end
    end

    if @collection_id
      @collection = Collection.find_by_repository_id(@collection_id)
      @items = @items.where(Item::SolrFields::COLLECTION => @collection_id)
    end

    metadata_profile = effective_metadata_profile
    @items = @items.facetable_fields(metadata_profile.solr_facet_fields)

    # Sort by the explicit sort, if provided; otherwise sort by the metadata
    # profile's default sort, if present; otherwise sort by relevance.
    sort = nil
    if @sort.present?
      sort = @sort
    elsif metadata_profile.default_sortable_element
      sort = metadata_profile.default_sortable_element.solr_single_valued_field
    end
    @items = @items.order("#{sort} asc") if sort

    @items = @items.start(@start).limit(@limit)

    @loaded = true
  end

  ##
  # @return [Set<Role>] Set of Roles associated with the client user, if
  #                     available, or the client hostname/IP address otherwise.
  #
  def roles
    return Set.new(@client_user.roles) if @client_user
    return Role.all_matching_hostname_or_ip(@client_hostname, @client_ip) if
        @client_hostname or @client_ip
    Set.new
  end

end