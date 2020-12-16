module Api

  class CollectionsController < ApiController

    ##
    # Responds to GET /api/collections
    #
    def index
      @start = params[:start].to_i
      @limit = params[:limit].to_i
      @limit = DEFAULT_RESULTS_LIMIT if @limit < 1
      @limit = MAX_RESULTS_LIMIT if @limit > MAX_RESULTS_LIMIT

      relation = Collection.search.
          aggregations(false).
          search_children(true).
          include_unpublished(true).
          include_restricted(true).
          facet_filters(params[:fq]).
          query_all(params[:q]).
          order(Collection::IndexFields::TITLE).
          start(@start).
          limit(@limit)
      @count       = relation.count
      @collections = relation.to_a

      render json: {
          start: @start,
          limit: @limit,
          numResults: @count,
          results: @collections.to_a.map { |c|
            { title: c.title, id: c.repository_id, url: api_collection_url(c) }
          }
      }
    end

  end

end
