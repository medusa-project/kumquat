##
# Favorites are saved in a cookie named "favorites".
#
class FavoritesController < WebsiteController

  COOKIE_DELIMITER = ','

  before_action :set_browse_context
  after_action :purge_invalid_favorites

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)
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
      format.js
      format.zip do
        # See the documentation for format.zip() in ItemsController.index().
        #
        # Check if there are any selected items present in the params.
        # If so, include only those. Otherwise, include all favorites.
        if params[:ids].present?
          item_ids = params[:ids].split(',')
        else
          item_ids = @items.to_a.map(&:repository_id)
        end

        download = Download.create
        DownloadZipJob.perform_later(item_ids, 'favorites', download)
        redirect_to download_url(download)
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
