class CollectionsController < WebsiteController

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = 40
    query = !params[:q].blank? ? "#{Solr::Fields::SEARCH_ALL}:#{params[:q]}" : nil
    @collections = Collection.where(query).
        where(Solr::Fields::PUBLISHED => true).
        order(Solr::Fields::TITLE).start(@start).limit(@limit)
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @num_shown = [@limit, @collections.total_length].min
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

    # Get a random image item to show
    media_types = %w(image/jp2 image/jpeg image/png image/tiff).join(' OR ')
    @item = Item.where(Solr::Fields::COLLECTION => @collection.id).
        where(Solr::Fields::PUBLISHED => true).
        where("(#{Solr::Fields::ACCESS_MASTER_MEDIA_TYPE}:(#{media_types}) OR "\
        "#{Solr::Fields::PRESERVATION_MASTER_MEDIA_TYPE}:(#{media_types}))").
        facet(false).order(:random).limit(1).first
  end

end
