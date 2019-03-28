##
# Provides a convenient ActiveRecord-style Builder interface for cross-entity
# search. Results may include instances of any indexed class.
#
# N.B.: All entities being searched must have an indexed
# `effectively_published` field.
#
class EntityFinder < AbstractFinder

  ALL_ENTITIES = [Agent, Collection, Item]

  def initialize
    super
    @include_classes                = ALL_ENTITIES
    @exclude_item_variants          = []
    @include_only_native_collections = false
    @include_unpublished            = false
    @last_modified_after            = nil
    @last_modified_before           = nil
    @only_described                 = false
  end

  ##
  # @param variants [String] One or more Item::Variants constant values.
  # @return [self]
  #
  def exclude_item_variants(*variants)
    @exclude_item_variants = variants
    self
  end

  ##
  # @param classes [Class] One or more model classes to search. All are
  #                        searched by default.
  # @return [self]
  #
  def include_classes(*classes)
    @include_classes = classes
    self
  end

  ##
  # @param boolean [Boolean] If true, only collections whose content resides in
  #                          the application will be included.
  # @return [self]
  #
  def include_only_native_collections(boolean)
    @include_only_native_collections = boolean
    self
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param time [Time]
  # @return [self]
  #
  def last_modified_after(time)
    @last_modified_after = time
    self
  end

  ##
  # @param time [Time]
  # @return [self]
  #
  def last_modified_before(time)
    @last_modified_before = time
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [ItemFinder] self
  #
  def only_described(boolean)
    @only_described = boolean
    self
  end

  ##
  # @return [Enumerable<Item>]
  #
  def to_a
    load
    if @response['hits']
      return @response['hits']['hits'].map { |r|
        case r['_type'].downcase
        when 'agent'
          Agent.find(r['_id'])
        when 'item'
          Item.find_by_repository_id(r['_source']['k_repository_id'])
        when 'collection'
          Collection.find_by_repository_id(r['_source']['k_repository_id'])
        end
      }.select(&:present?)
    end
    []
  end

  protected

  def get_response
    index_names = @include_classes.map { |c|
      ElasticsearchIndex.current_index(c.const_get(:ELASTICSEARCH_INDEX)) }.join(',')
    result = @client.query(index_names, build_query)
    JSON.parse(result)
  end

  def metadata_profile
    MetadataProfile.default
  end

  private

  ##
  # @return [String] JSON string.
  #
  def build_query
    json = Jbuilder.encode do |j|
      j.query do
        j.bool do
          # Query
          if @query.present?
            j.must do
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.query_string do
                j.query sanitized_query
                j.default_field @query[:field]
                j.default_operator 'AND'
                j.lenient true
              end
            end
          end

          if @filters.any? or @only_described or !@include_unpublished or
              @last_modified_before or @last_modified_after
            j.filter do
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

              unless @include_unpublished
                j.child! do
                  j.term do
                    j.set! ElasticsearchIndex::PUBLICLY_ACCESSIBLE_FIELD, true
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

          # Results must either have an effective allowed role (EAR) matching
          # one of the user's roles, or no EARs, indicating that they are
          # public, effective denied roles notwithstanding.
          j.should do
            if @user_roles.any?
              j.child! do
                j.terms do
                  j.set! Item::IndexFields::EFFECTIVE_ALLOWED_ROLES,
                         @user_roles
                end
              end
            end
            j.child! do
              j.range do
                j.set! Item::IndexFields::EFFECTIVE_ALLOWED_ROLE_COUNT do
                  j.lte 0
                end
              end
            end
          end
          j.minimum_should_match 1

          if @user_roles.any? or @exclude_item_variants.any? or
              @include_only_native_collections
            j.must_not do
              if @user_roles.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_DENIED_ROLES,
                           @user_roles
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

              if @include_only_native_collections
                j.child! do
                  j.term do
                    j.set! Collection::IndexFields::NATIVE, false
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
      if @start.present?
        j.from @start
      end

      # Limit
      if @limit.present?
        j.size @limit
      end
    end

    # For debugging
    #File.write('query.json', JSON.pretty_generate(JSON.parse(json)))
    # curl -XGET 'localhost:9200/items_development/_search?size=0&pretty' -H 'Content-Type: application/json' -d @query.json

    json
  end

end