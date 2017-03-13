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
    @stats = false
  end

  ##
  # @param collection_id [Integer]
  # @return [ItemFinder] self
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
  # @param variants [Enumerable<String>] Array of Item::Variants constant
  #                                      values.
  # @return [ItemFinder] self
  #
  def exclude_variants(variants)
    @exclude_variants = variants
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [ItemFinder] self
  #
  def include_children(boolean)
    @include_children = boolean
    self
  end

  ##
  # @param variants [Enumerable<String>, nil] Array of Item::Variants constant
  #                                           values. Supply nil to specify no
  #                                           variant.
  # @return [ItemFinder] self
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
  # @return [ItemFinder] self
  #
  def media_types(types)
    @media_types = types.respond_to?(:each) ? types : [types]
    self
  end

  ##
  # Enables statistics.
  # @param bool [Boolean]
  # @return [ItemFinder] self
  #
  def stats(bool)
    @stats = bool
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
  # For this to work, `stats()` must have been called with an argument of
  # `true`.
  #
  # @return [Integer]
  # @raises [ActiveRecord::RecordNotFound] If a collection ID that does not
  #                                        exist has been assigned to the
  #                                        instance.
  #
  def total_byte_size
    load
    @items.stats[Item::SolrFields::TOTAL_BYTE_SIZE]['sum'].to_i
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

    if @stats
      @items = @items.stats_field(Item::SolrFields::TOTAL_BYTE_SIZE)
    end

    role_keys = roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @items = @items.filter("(#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:(#{role_keys.join(' OR ')}) "\
          "OR (*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]))")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @items = @items.filter("-#{Item::SolrFields::EFFECTIVE_DENIED_ROLES}:(#{role_keys.join(' OR ')})")
    elsif @client_ip.present? or @client_hostname.present?
      @items = @items.filter("*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]")
    end

    @items = @items.filter(Item::SolrFields::PARENT_ITEM => :null) unless @include_children

    @items = @items.filter(@filter_queries)
    @items = @items.default_field(@default_field) if @default_field

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