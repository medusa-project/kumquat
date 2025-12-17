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

    search = SimpleCollectionSearch.new(query: @permitted_params[:q])
    search.facet_filters(@permitted_params[:fq])
    search.start(@start).limit(@limit)

    @collections = search.results
    @count = search.count

    search.aggregations(true)
    @facets = search.facets 

    @current_page = (@start / @limit) + 1
    @num_results_shown = [@collections.count, @limit].min
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