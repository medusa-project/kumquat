##
# Provides a high-level item query interface using the Builder pattern.
#
class ItemFinder < AbstractFinder

  def initialize
    super
    @exclude_variants = []
    @include_children = false
    @include_variants = []
    @media_types = []
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
  # @raises [ActiveRecord::RecordNotFound] If a collection ID that does not
  #                                        exist has been assigned to the
  #                                        instance.
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
  # @param variants [Array<String>] Array of Item::Variants constant values.
  # @return [self]
  #
  def exclude_variants(variants)
    @exclude_variants = variants
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
  # @param variants [Array<String>] Array of Item::Variants constant values.
  #                                 Supply a nil value to specify no variant.
  # @return [self]
  #
  def include_variants(variants)
    @include_variants = variants.map do |v|
      v = "(-#{Item::SolrFields::VARIANT}:[* TO *] AND *:*)" if v.nil?
      v
    end
    self
  end

  ##
  # @param types [Enumerable<String>,String]
  #
  def media_types(types)
    @media_types = types.respond_to?(:each) ? types : [types]
    self
  end

  ##
  # @return [Enumerable<Item>]
  # @raises [ActiveRecord::RecordNotFound] If a collection ID that does not
  #                                        exist has been assigned to the
  #                                        instance.
  #
  def to_a
    load
    @items
  end

  ##
  # @return [String]
  #
  def to_s
    "Collection: #{@collection_id}\n"\
    "Query: #{@query}\n"\
    "Sort: #{@sort}\n"\
    "Start: #{@start}\n"\
    "Limit: #{@limit}\n"\
    "Client Host: #{@client_hostname}\n"\
    "Client IP: #{@client_ip}\n"\
    "Client User: #{@client_user}\n"\
    "Include children: #{@include_children}\n"\
    "Include unpublished: #{@include_unpublished}\n"\
    "Num Results: #{@items&.length}\n"
  end

  private

  def load
    return if @loaded

    @items = Item.solr.all

    unless @include_unpublished
      @items = @items.filter(Item::SolrFields::PUBLISHED => true).
          filter(Item::SolrFields::COLLECTION_PUBLISHED => true)
    end
    if @media_types.any?
      @items = @items.filter(Item::SolrFields::ACCESS_MASTER_MEDIA_TYPE => "(#{@media_types.join(' OR ')})")
    end

    if @include_variants.any?
      @items = @items.filter("#{Item::SolrFields::VARIANT}:(#{@include_variants.join(' OR ')})")
    end
    if @exclude_variants.any?
      @items = @items.filter("-#{Item::SolrFields::VARIANT}:(#{@exclude_variants.join(' OR ')})")
    end

    @items = @items.where(@query) if @query

    role_keys = roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @items = @items.filter("(#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:(#{role_keys.join(' OR ')}) "\
          "OR (*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]))")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @items = @items.filter("-#{Item::SolrFields::EFFECTIVE_DENIED_ROLES}:(#{role_keys.join(' OR ')})")
    else
      @items = @items.filter("*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]")
    end

    @items = @items.filter(Item::SolrFields::PARENT_ITEM => :null) unless @include_children

    @items = @items.filter(@filter_queries)

    if @collection_id
      @collection = Collection.find_by_repository_id(@collection_id)
      raise ActiveRecord::RecordNotFound unless @collection
      @items = @items.filter(Item::SolrFields::COLLECTION => @collection_id)
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
    @items = @items.order(*sort)

    @items = @items.operator(:and).start(@start).limit(@limit)

    @loaded = true
  end

end