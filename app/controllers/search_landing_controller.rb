class SearchLandingController < WebsiteController 
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit, :tab]

  before_action :set_sanitized_params
  def index 
    @start = [@permitted_params[:start].to_i.abs, max_start].min
    @limit = window_size

    # Always search collections
    search = SimpleCollectionSearch.new(query: @permitted_params[:q])
    search.facet_filters(@permitted_params[:fq])
    search.start(@start).limit(@limit)

    @collections = search.results
    @count = search.count

    search.aggregations(true)
    @facets = search.facets

    @current_page = (@start / @limit) + 1
    @num_results_shown = [@collections.count, @limit].min

    # TEMPORARY: Debug logging for facets
    Rails.logger.info "=== COLLECTION SEARCH DEBUG ==="
    Rails.logger.info "Query: '#{@permitted_params[:q]}'"
    Rails.logger.info "Total results: #{@count}"
    Rails.logger.info "Collections returned: #{@collections.count}"
    Rails.logger.info "Facets count: #{@facets&.count || 0}"
    @facets&.each do |facet|
      Rails.logger.info "  Facet: #{facet.name} (#{facet.field}) - #{facet.terms.count} terms"
      facet.terms.each do |term|
        Rails.logger.info "    - #{term.label}: #{term.count}"
      end
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