##
# Favorites are saved in a cookie named "favorites".
#
class FavoritesController < WebsiteController

  COOKIE_DELIMITER = ','

  before_action :set_browse_context, :set_sanitized_params
  after_action :purge_invalid_favorites

  ##
  # Responds to GET /favorites
  #
  def index
    @items = nil
    @count = 0
    @num_results_shown = 0
    @total_byte_size = 0

    if request.format == :zip
      @start = 0
      @limit = ElasticsearchClient::MAX_RESULT_WINDOW
    else
      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)
    end

    if cookies[:favorites].present?
      ids = cookies[:favorites].split(COOKIE_DELIMITER)
      if ids.any?
        finder = ItemFinder.new.
            user_roles(request_roles).
            aggregations(false).
            filter(Item::IndexFields::REPOSITORY_ID, ids).
            start(@start).
            limit(@limit)
        @items = finder.to_a
        @count = finder.count
        @num_results_shown = @items.length
        @total_byte_size = finder.total_byte_size
      end
    end

    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @num_downloadable_items = @num_results_shown

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
          item_ids = @items.map(&:repository_id)
        end

        download = Download.create(ip_address: request.remote_ip)
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

  def set_sanitized_params
    @permitted_params = params.permit(:start)
  end

end
