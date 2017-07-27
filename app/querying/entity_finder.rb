##
# Provides a high-level interface to query across entity classes. Results may
# include instances of any class that includes SolrQuerying.
#
# N.B. All entities being searched must have an indexed
# `effectively_published_bi` field.
#
class EntityFinder < AbstractFinder

  def initialize
    super
    @exclude_item_variants = []
  end

  ##
  # @return [Integer]
  #
  def count
    load
    @results.count
  end

  ##
  # @param variants [Enumerable<String>] Array of Item::Variants constant values.
  # @return [self]
  #
  def exclude_item_variants(variants)
    @exclude_item_variants = variants
    self
  end

  ##
  # @return [Enumerable<ActiveRecord::Base>]
  #
  def to_a
    load
    @results
  end

  private

  def load
    return if @loaded

    # Instantiate a Relation to search across entities by providing a magic
    # constructor argument.
    @results = Relation.new(SolrQuerying)

    if @exclude_item_variants.any?
      @results = @results.filter("-#{Item::SolrFields::VARIANT}:(#{@exclude_item_variants.join(' OR ')})")
    end

    unless @include_unpublished
      @results = @results.filter('effectively_published_bi': true)
    end

    if @only_described
      @results = @results.filter("-#{Item::SolrFields::DESCRIBED}:false")
    end

    @results = @results.where(@query) if @query

    role_keys = roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @results = @results.filter("(#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:(#{role_keys.join(' OR ')}) "\
          "OR (*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]))")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @results = @results.filter("-#{Item::SolrFields::EFFECTIVE_DENIED_ROLES}:(#{role_keys.join(' OR ')})")
    else
      @results = @results.filter("*:* -#{Item::SolrFields::EFFECTIVE_ALLOWED_ROLES}:[* TO *]")
    end

    @results = @results.filter(@filter_queries)
    @results = @results.default_field(@default_field) if @default_field

    metadata_profile = MetadataProfile.default
    @results = @results.facetable_fields(metadata_profile.solr_facet_fields)

    # Sort by the explicit sort, if provided; otherwise sort by the metadata
    # profile's default sort, if present; otherwise sort by relevance.
    sort = nil
    if @sort.present?
      sort = @sort
    elsif metadata_profile.default_sortable_element
      sort = metadata_profile.default_sortable_element.solr_single_valued_field
    end
    if sort.join('').length > 0
      @results = @results.order(*sort)
    else
      @results = @results.order({ Configuration.instance.solr_class_field => :asc },
                                { 'score' => :desc })
    end

    @results = @results.operator(:and).start(@start).limit(@limit)

    @loaded = true
  end

end