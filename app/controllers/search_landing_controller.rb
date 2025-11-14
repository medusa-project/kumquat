class SearchLandingController < WebsiteController
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit]

  before_action :set_sanitized_params
  def index
    @start = [@permitted_params[:start].to_i.abs, max_start].min
    @limit = window_size

    # Initialize simple search
    search = SimpleItemSearch.new(query: @permitted_params[:q])

    search.start(@start).limit(@limit)

    @items = search.results
    @count = search.count

    search.aggregations(true)
    @facets = search.facets

    @current_page = (@start / @limit) + 1
    @num_results_shown = [@items.count, @limit].min

    Rails.logger.info "=== SIMPLE SEARCH REQUEST ==="
    Rails.logger.info "Query: '#{@permitted_params[:q]}'"
    Rails.logger.info "Total results: #{@count}"
    Rails.logger.info "Items returned: #{@items.count}"
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