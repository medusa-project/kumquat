class ItemsController < WebsiteController

  class BrowseContext
    BROWSING_ALL_ITEMS = 0
    BROWSING_COLLECTION = 1
    SEARCHING = 2
    FAVORITES = 3
  end

  before_action :set_browse_context, only: :index

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
    @items = Item.where("-#{Solr::Fields::PARENT_ITEM}:[* TO *]").where(params[:q])
    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @items = @items.facet(fq) }
    else
      @items = @items.facet(params[:fq])
    end
    if params[:collection_id]
      @collection = Collection.find(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
      @items = @items.where(Solr::Fields::COLLECTION => @collection.id)
    end
    # if there is no user-entered query, sort by title. Otherwise, use the
    # default sort, which is by relevance
    @items = @items.order(Solr::Fields::TITLE) if params[:q].blank?
    @items = @items.start(@start).limit(@limit)
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @num_results_shown = [@limit, @items.total_length].min

    # if there are no results, get some suggestions
    if @items.total_length < 1 and params[:q].present?
      @suggestions = Solr.new.suggestions(params[:q])
    end
  end

  ##
  # Redirects to an item's master bytestream.
  #
  # Responds to GET /items/:id/master
  #
  def master_bytestream
    @item = Item.find_by_web_id_si(params[:web_id])
    raise ActiveRecord::RecordNotFound unless @item
    redirect_to bytestream_url(@item.master_bytestream)
  end

  ##
  # Responds to POST /search. Translates the input from the advanced search
  # form into a query string compatible with ItemsController.index, and
  # 302-redirects to it.
  #
  def search
    where_clauses = []

    # fields
    if params[:fields].any?
      params[:fields].each_with_index do |field, index|
        if params[:terms].length > index and !params[:terms][index].blank?
          where_clauses << "#{field}:#{params[:terms][index]}"
        end
      end
    end

    # collections
    keys = []
    if params[:keys].any?
      keys = params[:keys].select{ |k| !k.blank? }
    end
    if keys.any? and keys.length < Collection.all.length
      where_clauses << "#{Solr::Fields::COLLECTION}:+(#{keys.join(' ')})"
    end

    redirect_to items_path(q: where_clauses.join(' AND '))
  end

  def show
    @item = Item.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @item

    @pages = @item.parent ? @item.parent.children : @item.items
  end

  private

  ##
  # The browse context is "what the user is doing" -- necessary information in
  # item view in which we need to know the "mode of entry" in order to display
  # appropriate navigational controls, either "back to results" or "back to
  # collection" etc.
  #
  def set_browse_context
    session[:browse_context_url] = request.url
    if !params[:q].blank?
      session[:browse_context] = BrowseContext::SEARCHING
    elsif !params[:repository_collection_key]
      session[:browse_context] = BrowseContext::BROWSING_ALL_ITEMS
    else
      session[:browse_context] = BrowseContext::BROWSING_COLLECTION
    end
  end

end
