class ItemsController < WebsiteController

  class BrowseContext
    BROWSING_ALL_ITEMS = 0
    BROWSING_COLLECTION = 1
    SEARCHING = 2
    FAVORITES = 3
  end

  before_action :set_browse_context, only: :index

  ##
  # Retrieves an item's access master bytestream.
  #
  # Responds to GET /items/:item_id/access-master
  #
  def access_master_bytestream
    item = Item.find(params[:item_id])
    send_bytestream(item, Bytestream::Type::ACCESS_MASTER)
  end

  def index
    @start = params[:start] ? params[:start].to_i : 0
    @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
    @items = Item.solr.where(Item::SolrFields::PUBLISHED => true).
        where(Item::SolrFields::PARENT_ITEM => :null).where(params[:q])
    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @items = @items.facet(fq) }
    else
      @items = @items.facet(params[:fq])
    end
    if params[:collection_id]
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
      @items = @items.where(Item::SolrFields::COLLECTION => @collection.repository_id)
    end

    @metadata_profile = @collection ?
        @collection.effective_metadata_profile :
        MetadataProfile.find_by_default(true)
    @items = @items.facetable_fields(@metadata_profile.solr_facet_fields)

    # Sort by ?sort= parameter if present; otherwise sort by the metadata
    # profile's default sort, if present; otherwise sort by relevance.
    sort = nil
    if params[:sort].present?
      sort = params[:sort]
    elsif @metadata_profile.default_sortable_element_def
      sort = @metadata_profile.default_sortable_element_def.solr_single_valued_field
    end
    @items = @items.order("#{sort} asc") if sort

    @items = @items.start(@start).limit(@limit)

    respond_to do |format|
      format.html do
        @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
        @count = @items.count
        @num_results_shown = [@limit, @count].min

        # if there are no results, get some suggestions
        if @count < 1 and params[:q].present?
          @suggestions = Solr.instance.suggestions(params[:q])
        end
      end
      format.json do
        render json: @items.to_a.map { |item|
          {
              id: item.repository_id,
              url: item_url(item)
          }
        }
      end
    end
  end

  ##
  # Retrieves an item's preservation master bytestream.
  #
  # Responds to GET /items/:id/preservation-master
  #
  def preservation_master_bytestream
    item = Item.find(params[:item_id])
    send_bytestream(item, Bytestream::Type::PRESERVATION_MASTER)
  end

  ##
  # Responds to POST /search. Translates the input from the advanced search
  # form into a query string compatible with ItemsController.index, and
  # 302-redirects to it.
  #
  def search
    where_clauses = []
    filter_clauses = []

    # fields
    if params[:fields].any?
      params[:fields].each_with_index do |field, index|
        if params[:terms].length > index and !params[:terms][index].blank?
          where_clauses << "#{field}:#{params[:terms][index]}"
        end
      end
    end

    # collections
    ids = []
    if params[:ids].any?
      ids = params[:ids].select{ |k| !k.blank? }
    end
    if ids.any?
      filter_clauses << "#{Item::SolrFields::COLLECTION}:(#{ids.join(' ')})"
    end

    redirect_to items_path(q: where_clauses.join(' AND '), fq: filter_clauses)
  end

  def show
    @item = Item.find_by_repository_id(params[:id])
    unless @item.published
      render 'error/error', status: :forbidden, locals: {
          status_code: 403,
          status_message: 'Forbidden',
          message: 'This item is not published.'
      }
    end

    respond_to do |format|
      format.html {
        @parent = @item.parent
        @pages = @parent ? @parent.pages : @item.pages

        @relative_parent = @parent ? @parent : @item
        @relative_child = @parent ? @item : @pages.first

        @previous_item = @relative_child ? @relative_child.previous : nil
        @next_item = @relative_child ? @relative_child.next : nil
      }
      format.json { render json: @item }
    end
  end

  private

  ##
  # @param item [Item]
  # @param type [Integer] One of the `Bytestream::Type` constants
  #
  def send_bytestream(item, type)
    unless item.published
      render 'error/error', status: :forbidden, locals: {
          status_code: 403,
          status_message: 'Forbidden',
          message: 'This item is currently not published.'
      }
    end
    bs = item.bytestreams.where(bytestream_type: type).select(&:exists).first
    if bs
      if bs.url
        redirect_to bs.url, status: 303
      else
        send_file(bs.absolute_local_pathname)
      end
    else
      render status: 404, text: 'Not found.'
    end
  end

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
    elsif !params[:collection_id]
      session[:browse_context] = BrowseContext::BROWSING_ALL_ITEMS
    else
      session[:browse_context] = BrowseContext::BROWSING_COLLECTION
    end
  end

end
