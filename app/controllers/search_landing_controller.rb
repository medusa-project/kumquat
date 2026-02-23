class SearchLandingController < WebsiteController 
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit, :tab]

  before_action :set_sanitized_params
  
  include SearchHelper
  
  def index 
    # Get total available counts for display
    @total_available_count = total_available_dls_count
    
    @start = [@permitted_params[:start].to_i.abs, max_start].min
    @limit = window_size

    # Use unified search for both collections and items
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

    # TEMPORARY: Debug logging for unified search
    Rails.logger.info "=== UNIFIED SEARCH DEBUG ==="
    Rails.logger.info "Query: '#{@permitted_params[:q]}'"
    Rails.logger.info "Total results: #{@count} (#{@collection_count} collections, #{@item_count} items)"
    Rails.logger.info "Results returned: #{@results.count}"
    Rails.logger.info "Facets count: #{@facets&.count || 0}"

    respond_to do |format|
      format.html
      format.js
    end
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
end