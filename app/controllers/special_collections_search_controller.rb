class SpecialCollectionsSearchController < WebsiteController 
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit]
  before_action :set_sanitized_params

  def index 
    # Redirect to browse all collections if search submitted with empty query 
    if @permitted_params[:q].blank? && @permitted_params[:commit].present?
      redirect_to search_landing_path 
      return 
    end

    @start = [@permitted_params[:start].to_i.abs, max_start].min 
    @limit = window_size

    # Unified search for both collections and items
    search = SpecialCollectionSearch.new(
      query: @permitted_params[:q],
      start: @start,
      limit: @limit,
      facet_filters: @permitted_params[:fq]
    )
    search.execute!

    @results = search.results
    @count = search.count
    @collection_count = search.collection_count
    @item_count = search.item_count
    @facets = search.facets

    @current_page = (@start / @limit) + 1
    @num_results_shown = [@results.count, @limit].min
  end

  private 
  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

  def window_size 
    40 
  end

  def max_start
    9960
  end

  def get_total_available_count
    # Get total count of DLS collections
    collection_count = Collection.search
      .aggregations(false)
      .include_unpublished(false)
      .include_restricted(false) 
      .filter(Collection::IndexFields::PUBLISHED_IN_DLS, true)
      .count

    # Get total count of DLS items
    item_count = Item.search
      .aggregations(false)
      .include_unpublished(false)
      .include_restricted(false)
      .include_publicly_inaccessible(false)
      .filter(Item::IndexFields::PUBLISHED, true)
      .count

    collection_count + item_count
  end
end