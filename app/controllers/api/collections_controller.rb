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

      finder = CollectionFinder.new.
          include_children(true).
          include_private_in_medusa(true).
          include_unpublished_in_dls(true).
          filter_queries(params[:fq]).
          query(params[:q]).
          order(Collection::SolrFields::TITLE).
          start(@start).
          limit(@limit)
      @count = finder.count
      @collections = finder.to_a

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
