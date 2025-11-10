class SearchLandingController < ApplicationController
  PERMITTED_PARAMS = [{ fq: [] }, :q, :sort, :start, :utf8, :commit]

  before_action :set_sanitized_params
  def index
    @start = [@permitted_params[:start].to_i.abs, max_start].min
    @limit = window_size

    # Initialize simple search
    search = SimpleItemSearch.new(query: params[:q])

    # Apply pagination
    search.start(@start).limit(@limit)

    # Get results
    @items = search.results
    @count = search.count

    # Get facets
    search.aggregations(true)
    @facets = search.facets

    @current_page = (@start / @limit) + 1
    @num_results_shown = [@items.count, @limit].min

    Rails.logger.info "=== SIMPLE SEARCH REQUEST ==="
    Rails.logger.info "Query: '#{params[:q]}'"
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


                  

    ## The below count only gives about 1,000 which is far lower than the expected 316k from the above
    #
    # collections = Collection.where(published_in_dls: true).pluck(:repository_id)
    # @item_count = ItemRelation.new.filter('sys_k_collection', collections).count 


    # @results = nil 
    # if params[:query].present? || params[:field].present?
    #   relation = ItemRelation.new 
    #   process_search_query(relation)
    #   @results = relation.to_a
    # end
end