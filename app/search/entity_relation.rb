##
# Provides a convenient ActiveRecord-style Builder interface for cross-entity
# search. By default, results may include instances of any indexed class. Limit
# this using {exclude_types}.
#
# N.B.: All entities being searched must have an indexed
# `effectively_published` field.
#
class EntityRelation < AbstractRelation

  LOGGER = CustomLogger.new(EntityRelation)

  def initialize
    super
    @bypass_authorization  = false
    @exclude_item_variants = []
    @include_types         = %w(Agent Collection Item)
    @include_restricted    = false
    @include_unpublished   = false
    @last_modified_after   = nil
    @last_modified_before  = nil
    @only_described        = false
  end

  ##
  # @param boolean [Boolean] Whether to return all results. If true, calls to
  #                          {host_groups} are ignored.
  # @return [EntityRelation] The instance.
  #
  def bypass_authorization(boolean)
    @bypass_authorization = boolean
    self
  end

  ##
  # @param variants [String] One or more {Item::Variants} constant values.
  # @return [EntityRelation] The instance.
  #
  def exclude_item_variants(*variants)
    @exclude_item_variants = variants
    self
  end

  ##
  # @param bool [Boolean]
  # @return [EntityRelation] The instance.
  #
  def include_restricted(bool)
    @include_restricted = bool
    self
  end

  ##
  # @param types [Class,String]
  # @return [EntityRelation] The instance.
  #
  def include_types(*types)
    @include_types = types.map(&:to_s)
    self
  end

  ##
  # @param bool [Boolean]
  # @return [EntityRelation] The instance.
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param time [Time]
  # @return [EntityRelation] The instance.
  #
  def last_modified_after(time)
    @last_modified_after = time
    self
  end

  ##
  # @param time [Time]
  # @return [EntityRelation] The instance.
  #
  def last_modified_before(time)
    @last_modified_before = time
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [EntityRelation] The instance.
  #
  def only_described(boolean)
    @only_described = boolean
    self
  end

  ##
  # @return [Enumerable<Agent,Collection,Item>]
  #
  def to_a
    load
    if @response_json['hits']
      return @response_json['hits']['hits'].map { |r|
        case r['_source'][ElasticsearchIndex::StandardFields::CLASS].downcase
        when 'agent'
          id    = r['_id']
          agent = Agent.find_by_id(id)
          LOGGER.debug("to_a(): #{id} is missing from the database") unless agent
          agent
        when 'item'
          id   = r['_source'][Item::IndexFields::REPOSITORY_ID]
          item = Item.find_by_repository_id(id)
          LOGGER.debug("to_a(): #{id} is missing from the database") unless item
          item
        when 'collection'
          id  = r['_source'][Collection::IndexFields::REPOSITORY_ID]
          col = Collection.find_by_repository_id(id)
          LOGGER.debug("to_a(): #{id} is missing from the database") unless col
          col
        end
      }.select(&:present?)
    end
    []
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
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.simple_query_string do
                j.query sanitized_query
                j.fields [@query[:field]]
                j.default_operator 'AND'
                j.lenient true
              end
            end
          end

          if @filters.any? || @only_described || !@include_unpublished ||
              @last_modified_before || @last_modified_after
            j.filter do
              j.child! do
                j.terms do
                  j.set! Item::IndexFields::CLASS, @include_types
                end
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

              if @only_described
                j.child! do
                  j.term do
                    j.set! Item::IndexFields::DESCRIBED, true
                  end
                end
              end

              unless @include_restricted
                j.child! do
                  j.term do
                    j.set! ElasticsearchIndex::StandardFields::RESTRICTED, false
                  end
                end
              end

              unless @include_unpublished
                j.child! do
                  j.term do
                    j.set! ElasticsearchIndex::StandardFields::PUBLICLY_ACCESSIBLE, true
                  end
                end
              end

              if @last_modified_before or @last_modified_after
                j.child! do
                  j.range do
                    j.set! Item::IndexFields::LAST_MODIFIED do
                      if @last_modified_after
                        j.gte @last_modified_after.iso8601
                      end
                      if @last_modified_before
                        j.lte @last_modified_before.iso8601
                      end
                    end
                  end
                end
              end
            end
          end

          unless @bypass_authorization
            # Results must either have an effective allowed host group (EAHG)
            # matching one of the client's host groups, or no EAHGs, indicating
            # that they are public, effective denied host groups
            # notwithstanding.
            j.should do
              if @host_groups.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS,
                           @host_groups
                  end
                end
              end
              j.child! do
                j.range do
                  j.set! Item::IndexFields::EFFECTIVE_ALLOWED_HOST_GROUP_COUNT do
                    j.lte 0
                  end
                end
              end
            end
            j.minimum_should_match 1
          end

          if @host_groups.any? || @exclude_item_variants.any?
            j.must_not do
              if @host_groups.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_DENIED_HOST_GROUPS,
                           @host_groups
                  end
                end
              end

              if @exclude_item_variants.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::VARIANT, @exclude_item_variants
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      if @aggregations
        j.aggregations do
          # TODO: collection
          metadata_profile.facet_elements.each do |field|
            j.set! field.indexed_keyword_field do
              j.terms do
                j.field field.indexed_keyword_field
                j.size @bucket_limit
              end
            end
          end
        end
      end

      # Ordering
      # Order by explicit orders, if provided; otherwise sort by the metadata
      # profile's default order, if present.
      if @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
              j.unmapped_type 'keyword'
            end
          end
        end
      else
        el = metadata_profile.default_sortable_element
        if el
          j.sort do
            j.set! el.indexed_sort_field, 'asc'
          end
        end
      end

      # Start
      j.from @start

      # Limit
      # ES requires from + size to be less than or equal to
      # ElasticsearchClient::MAX_RESULT_WINDOW
      j.size @limit - @start
    end
  end

end