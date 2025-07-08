##
# Provides a convenient ActiveRecord-style Builder interface for Item retrieval.
#
class ItemRelation < AbstractRelation

  LOGGER = CustomLogger.new(ItemRelation)

  def initialize
    super
    @collection                    = nil
    @exclude_variants              = []
    @include_children_in_results   = false
    @include_restricted            = false
    @include_publicly_inaccessible = false
    @include_unpublished           = false
    @include_variants              = []
    @item_set                      = nil
    @only_described                = false
    @parent_item                   = nil
    @search_children               = false
  end

  ##
  # @param collection [Collection]
  # @return [ItemRelation] The instance.
  #
  def collection(collection)
    @collection = collection
    self
  end

  def collections(ids)
    @collections = ids
    self
  end

  ##
  # @param variants [String] One or more `Item::Variants` constant values.
  # @return [ItemRelation] The instance.
  #
  def exclude_variants(*variants)
    @exclude_variants = variants
    self
  end

  ##
  # @param bool [Boolean] Whether to include children (even unmatching ones) in
  #                       results. Ordering by `Item::Variants::STRUCTURAL_SORT`
  #                       would then achieve a "flat tree" of results.
  # @return [ItemRelation] The instance.
  # @see search_children()
  #
  def include_children_in_results(bool)
    @include_children_in_results = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [ItemRelation] The instance.
  #
  def include_publicly_inaccessible(bool)
    @include_publicly_inaccessible = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [ItemRelation] The instance.
  #
  def include_restricted(bool)
    @include_restricted = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [ItemRelation] The instance.
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  ##
  # @param variants [String] One or more Item::Variants constant values.
  # @return [ItemRelation] The instance.
  #
  def include_variants(*variants)
    @include_variants = variants
    self
  end

  ##
  # @param item_set [ItemSet] Limit results to items within this ItemSet.
  # @return [ItemRelation] The instance.
  #
  def item_set(item_set)
    @item_set = item_set
    self
  end

  ##
  # @param boolean [Boolean]
  # @return [ItemRelation] The instance.
  #
  def only_described(boolean)
    @only_described = boolean
    self
  end

  ##
  # @param parent_item [Item]
  # @return [ItemRelation] The instance.
  #
  def parent_item(item)
    @parent_item = item
    self
  end

  ##
  # @param bool [Boolean] Whether to search and include matching children in
  #                       results. If false, child items (items with a non-nil
  #                       parent ID) will be excluded.
  # @return [ItemRelation] The instance.
  # @see include_children_in_results
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @return [Enumerable<Item>]
  #
  def to_a
    load
    # This is basically a "WHERE IN" query that preserves the order of the
    # results corresponding to the IDs in the "IN" clause.
    # TODO: monkey-patch ActiveRecord::Base?
    sql_arr = to_id_a.map{ |e| "\"#{e}\"" }.join(',')
    Item.joins("JOIN unnest('{#{sql_arr}}'::text[]) WITH ORDINALITY t(repository_id, ord) USING (repository_id)").
      order('t.ord')
  end

  def to_id_a
    load
    @response_json['hits']['hits']
      .map{ |r| r['_source'][Item::IndexFields::REPOSITORY_ID] }
  end


  protected

  def metadata_profile
    @collection&.effective_metadata_profile || MetadataProfile.default
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
              if !@exact_match
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html
                j.simple_query_string do
                  j.query @query[:query]
                  j.default_operator 'AND'
                  j.flags 'NONE'
                  j.lenient true
                  if @include_children_in_results
                    j.fields [@query[:field],
                              ItemElement.new(name: EntityElement.element_name_for_indexed_field(@query[:field])).parent_indexed_field]
                  else
                    j.fields [@query[:field]]
                  end
                end
              else
                j.term do
                  # Use the keyword field to get an exact match.
                  j.set! @query[:field] + EntityElement::KEYWORD_FIELD_SUFFIX,
                         @query[:query]
                end
              end
            end
          end

          j.filter do
            j.child! do
              j.term do
                j.set! Item::IndexFields::CLASS, 'Item'
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

            if @item_set
              j.child! do
                j.term do
                  j.set! Item::IndexFields::ITEM_SETS, @item_set.id
                end
              end
            end

            if @parent_item
              j.child! do
                j.term do
                  j.set! Item::IndexFields::PARENT_ITEM,
                         @parent_item.repository_id
                end
              end
            end

            if @collections
              j.child! do
                j.terms do
                  j.set! Item::IndexFields::COLLECTION, @collections
                end
              end
            elsif @collection 
              j.child! do 
                j.term do
                  j.set! Item::IndexFields::COLLECTION, @collection.repository_id
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
                  j.set! Item::IndexFields::RESTRICTED, false
                end
              end
            end

            if !@include_publicly_inaccessible && !@include_restricted
              j.child! do
                j.term do
                  j.set! Item::IndexFields::PUBLICLY_ACCESSIBLE, true
                end
              end
            end

            unless @include_unpublished
              j.child! do
                j.term do
                  j.set! Item::IndexFields::PUBLISHED, true
                end
              end
            end
          end

          if @host_groups.any? || @include_variants.any?
            j.should do
              if @host_groups.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::EFFECTIVE_ALLOWED_HOST_GROUPS,
                           @host_groups
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

              if @include_variants.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::VARIANT, @include_variants
                  end
                end
              end
            end
            j.minimum_should_match 1
          end

          if @exclude_variants.any? || (!@include_children_in_results && !@search_children)
            j.must_not do
              if @exclude_variants.any?
                j.child! do
                  j.terms do
                    j.set! Item::IndexFields::VARIANT, @exclude_variants
                  end
                end
              end

              if !@include_children_in_results && !@search_children
                j.child! do
                  j.exists do
                    j.field Item::IndexFields::PARENT_ITEM
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      j.aggregations do
        if @aggregations
          # Facetable elements in the metadata profile
          metadata_profile.facet_elements.each do |field|
            j.set! field.indexed_keyword_field do
              j.terms do
                j.field field.indexed_keyword_field
                j.size OpensearchClient::AGGREGATION_BUCKET_LIMIT
                j.order do
                  j.set! :_key, "asc"
                end
              end
            end
          end
        end

        # Total byte size
        j.set! BYTE_SIZE_AGGREGATION do
          j.sum do
            j.field Item::IndexFields::TOTAL_BYTE_SIZE
          end
        end
      end

      # Ordering
      # Order by explicit orders, if provided; otherwise sort by the metadata
      # profile's default order, if @orders is set to true; otherwise don't
      # sort.
      if @orders.respond_to?(:any?) && @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
              j.unmapped_type 'keyword'
            end
          end
        end
      elsif @orders
        el = metadata_profile.default_sortable_element
        if el
          j.sort do
            j.set! el.indexed_sort_field do
              j.order 'asc'
              j.unmapped_type 'keyword'
            end
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
  end

end