##
# Provides a high-level collection query interface using the Builder pattern.
#
class CollectionFinder < AbstractFinder

  def initialize
    super
    @include_unpublished_in_dls = false
    @sort = Collection::SolrFields::TITLE
  end

  ##
  # @return [Integer]
  #
  def count
    load
    @collections.count
  end

  ##
  # @param boolean [Boolean]
  # @return [self]
  #
  def include_unpublished_in_dls(boolean)
    @include_unpublished_in_dls = boolean
    self
  end

  ##
  # @return [Enumerable<Collection>]
  # @raises [ActiveRecord::RecordNotFound] If a collection ID that does not
  #                                        exist has been assigned to the
  #                                        instance.
  #
  def to_a
    load
    @collections
  end

  private

  def load
    return if @loaded

    @collections = Collection.solr.all

    unless @include_unpublished
      @collections = @collections.filter(Collection::SolrFields::PUBLISHED => true)
    end
    unless @include_unpublished_in_dls
      @collections = @collections.filter(Collection::SolrFields::PUBLISHED_IN_DLS => true)
    end

    @collections = @collections.where(@query) if @query

    role_keys = roles.map(&:key)
    if role_keys.any?
      # Include documents that have allowed roles matching one of the user
      # roles, or that have no effective allowed roles.
      @collections = @collections.filter("(#{Collection::SolrFields::ALLOWED_ROLES}:(#{role_keys.join(' OR ')}) "\
          "OR (*:* -#{Collection::SolrFields::ALLOWED_ROLES}:[* TO *]))")
      # Exclude documents that have denied roles matching one of the user
      # roles.
      @collections = @collections.filter("-#{Collection::SolrFields::DENIED_ROLES}:(#{role_keys.join(' OR ')})")
    else
      @collections = @collections.filter("*:* -#{Collection::SolrFields::ALLOWED_ROLES}:[* TO *]")
    end

    @collections = @collections.
        operator(:and).
        facetable_fields(Collection::solr_facet_fields.map{ |e| e[:name] }).
        filter(@filter_queries).
        order(@sort).
        start(@start).
        limit(@limit)

    @loaded = true
  end

end