##
# Favorites are saved in a cookie named "favorites".
#
class FavoritesController < WebsiteController

  COOKIE_DELIMITER = ','

  before_action :set_browse_context
  after_action :purge_invalid_favorites

  def index
    @start = params[:start] ? params[:start].to_i : 0
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
    @num_downloadable_items = @num_results_shown
    @total_byte_size = 0

    respond_to do |format|
      format.html
      format.zip do
        # First, check if there are any selected items present in the params.
        # If so, include only those. Otherwise, include all favorites.
        if params[:ids].present?
          ids = params[:ids].split(',')
          if ids.any?
            @items = Item.solr.operator(:or).where("id:(#{ids.join(' ')})").
                limit(9999)
          end
        end

        client = DownloaderClient.new
        begin
          download_url = client.download_url(@items.to_a, 'favorites')
        rescue => e
          flash['error'] = "#{e}"
          redirect_to :back
        else
          redirect_to download_url, status: 303
        end
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
