##
# Provides a high-level interface to query across all entity classes. Results
# may include any entity that includes SolrQuerying.
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

    unless @include_unpublished
      @results.filter("("\
          "  (#{Configuration.instance.solr_class_field}:\"Item\" "\
          "    AND #{Item::SolrFields::PUBLISHED}:true "\
          "    AND #{Item::SolrFields::COLLECTION_PUBLISHED}:true"\
          "  ) "\
          "  OR ("\
          "    #{Configuration.instance.solr_class_field}:\"Collection\" "\
          "    AND #{Collection::SolrFields::PUBLISHED}:true"\
          "  )"\
          "  OR ("\
          "    #{Configuration.instance.solr_class_field}:\"Agent\" "\
          "  )"\
          ")")
    end
    if @exclude_item_variants.any?
      @results = @results.filter("-#{Item::SolrFields::VARIANT}:(#{@exclude_item_variants.join(' OR ')})")
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