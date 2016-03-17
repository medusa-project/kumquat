class CollectionsController < WebsiteController

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = 40
    query = !params[:q].blank? ? "#{Solr::Fields::SEARCH_ALL}:#{params[:q]}" : nil
    @collections = Collection.where(query).
        where(Solr::Fields::PUBLISHED => true).
        order(Element.named('title').solr_single_valued_field).
        start(@start).limit(@limit)
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @num_shown = [@limit, @collections.total_length].min

    @medusa_collections = MedusaCollection.all.
        select{ |c| c.published and c.access_url }
  end

  def show
    @collection = Collection.find(params[:id])
    unless @collection.published
      render 'error/error', status: :forbidden, locals: {
          status_code: 403,
          status_message: 'Forbidden',
          message: 'This collection is not published.'
      }
    end
  end

end
