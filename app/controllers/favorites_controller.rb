class FavoritesController < WebsiteController

  COOKIE_DELIMITER = ','

  before_action :set_browse_context, only: :index

  def index
    @start = params[:start] ? params[:start].to_i : 0

    respond_to do |format|
      format.html do
        @limit = 50
        @items = Item.solr.none

        if cookies[:favorites].present?
          ids = cookies[:favorites].split(COOKIE_DELIMITER)
          if ids.any?
            @items = Item.solr.operator(:or).where("id:(#{ids.join(' ')})")
          end
        end

        @items = @items.start(@start).limit(@limit)
        @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
        @num_results_shown = [@limit, @items.total_length].min

        purge_invalid_favorites
      end
      format.zip do
        if cookies[:favorites].present?
          ids = cookies[:favorites].split(COOKIE_DELIMITER)
          if ids.any?
            ids = ids.join(',')
            # Redirect to the FavoritesZipDownloader Rack app.
            redirect_to "/favorites/download?items=#{ids}&start=#{@start}"
            return
          end
        end
        flash['error'] = 'No favorites to download.'
        redirect_to favorites_url
      end
    end
  end

  private

  ##
  # Rewrites the favorites cookie if there are any items in the cookie that
  # no longer exist in the repo.
  #
  def purge_invalid_favorites
    if request.format == :html and cookies[:favorites]
      ids = cookies[:favorites].split(COOKIE_DELIMITER)
      if ids.length != @items.count
        cookies[:favorites] = @items.map(&:repository_id).join(COOKIE_DELIMITER)
      end
    end
  end

  ##
  # See ItemsController.set_browse_context for documentation.
  #
  def set_browse_context
    session[:browse_context_url] = request.url
    session[:browse_context] = ItemsController::BrowseContext::FAVORITES
  end

end
