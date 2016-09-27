class ItemsController < WebsiteController

  include ActionController::Streaming

  class BrowseContext
    BROWSING_ALL_ITEMS = 0
    BROWSING_COLLECTION = 1
    SEARCHING = 2
    FAVORITES = 3
  end

  # Number of children to display per page in show-item view.
  PAGES_LIMIT = 15

  # API actions
  before_action :authorize_api_user, only: [:create, :destroy]
  before_action :check_api_content_type, only: :create
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  # Other actions
  before_action :load_item, only: [:access_master_bytestream, :files, :pages,
                                   :preservation_master_bytestream, :show]
  before_action :authorize_item, only: [:access_master_bytestream, :files,
                                        :pages, :preservation_master_bytestream]
  before_action :authorize_item, only: :show, unless: :using_api?
  before_action :set_browse_context, only: :index

  ##
  # Retrieves an item's access master bytestream.
  #
  # Responds to GET /items/:item_id/access-master
  #
  # The default is to send with a Content-Disposition of `attachment`. Supply a
  # `disposition` query variable of `inline` to override.
  #
  def access_master_bytestream
    send_bytestream(@item, Bytestream::Type::ACCESS_MASTER, params[:disposition])
  end

  ##
  # Responds to POST /items (protected by Basic auth)
  #
  def create
    # curl -X POST -u api_user:secret --silent -H "Content-Type: application/xml" -d @"/path/to/file.xml" localhost:3000/items?version=2
    begin
      item = ItemXmlIngester.new.ingest_xml(request.body.read,
                                            params[:version].to_i)
      url = item_url(item)
      render text: "OK: #{url}\n", status: :created, location: url
    rescue => e
      render text: "#{e}\n\n#{e.backtrace.join("\n")}\n", status: :bad_request
    end
  end

  ##
  # Responds to DELETE /items/:id
  #
  def destroy
    item = Item.find_by_repository_id(params[:id])
    begin
      raise ActiveRecord::RecordNotFound unless item
      item.destroy!
    rescue ActiveRecord::RecordNotFound => e
      render text: "#{e}", status: :not_found
    rescue => e
      render text: "#{e}", status: :internal_server_error
    else
      render text: 'Success'
    end
  end

  ##
  # Responds to GET /item/:id/files (XHR only)
  #
  def files
    if request.xhr?
      fresh_when(etag: @item) if Rails.env.production?
      set_files_ivar
      render 'items/files'
    else
      render status: 406, text: 'Not Acceptable'
    end
  end

  ##
  # Responds to GET /items
  #
  def index
    if params[:collection_id]
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
      return unless authorize(@collection)
    end

    @start = params[:start].to_i
    @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
    finder = ItemFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        collection_id(params[:collection_id]).
        query(params[:q]).
        include_children(params[:q].present?).
        facet_queries(params[:fq]).
        sort(params[:sort]).
        start(@start).
        limit(@limit)

    respond_to do |format|
      format.atom do
        @updated = @items.any? ?
            @items.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.html do
        @items = finder.to_a
        @current_page = finder.page
        @count = finder.count
        @num_results_shown = [@limit, @count].min
        @metadata_profile = finder.effective_metadata_profile

        # If there are no results, get some search suggestions.
        if @count < 1 and params[:q].present?
          @suggestions = finder.suggestions
        end

        fresh_when(etag: @items) if Rails.env.production?
      end
      format.json do
        @items = finder.to_a
        render json: {
            start: @start,
            numResults: @items.count,
            results: @items.map { |item|
              {
                  id: item.repository_id,
                  url: item_url(item)
              }
            }
          }
      end
      format.zip do
        # Redirect to the ZipDownloader Rack app, passing the IDs we want to
        # include in the zip file via the query string.
        # TODO: instantiating items is inefficient
        @items = finder.start(0).limit(999999).to_a
        ids = @items.map(&:id).join(',')
        if ids.length > 0
          redirect_to "/items/download?items=#{ids}"
        else
          flash['error'] = 'No items to download.'
          redirect_to :back
        end
      end
    end
  end

  ##
  # Responds to GET /item/:id/pages (XHR only)
  #
  def pages
    if request.xhr?
      fresh_when(etag: @item) if Rails.env.production?
      set_pages_ivar
      render 'items/pages'
    else
      render status: 406, text: 'Not Acceptable'
    end
  end

  ##
  # Retrieves an item's preservation master bytestream.
  #
  # Responds to GET /items/:id/preservation-master
  #
  # The default is to send with a Content-Disposition of `attachment`. Supply a
  # `disposition` query variable of `inline` to override.
  #
  def preservation_master_bytestream
    send_bytestream(@item, Bytestream::Type::PRESERVATION_MASTER,
                    params[:disposition])
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

  ##
  # Responds to GET /items/:id
  #
  def show
    fresh_when(etag: @item) if Rails.env.production?

    respond_to do |format|
      format.atom
      format.html do
        @parent = @item.parent
        @relative_parent = @parent ? @parent : @item

        set_files_ivar
        if @files.total_length > 0
          @relative_child = @files.first
        else
          set_pages_ivar
          @relative_child = @parent ? @item : @pages.first
        end

        @previous_item = @relative_child ? @relative_child.previous : nil
        @next_item = @relative_child ? @relative_child.next : nil
      end
      format.json do
        render json: @item.decorate
      end
      format.xml do
        # Authorization is required for unpublished items.
        if (@item.collection.published and @item.published) or authorize_api_user
          version = ItemXmlIngester::SCHEMA_VERSIONS.max
          if params[:version]
            if ItemXmlIngester::SCHEMA_VERSIONS.include?(params[:version].to_i)
              version = params[:version].to_i
            else
              render text: "Invalid schema version. Available versions: "\
                           "#{ItemXmlIngester::SCHEMA_VERSIONS.join(', ')}",
                     status: :bad_request
              return
            end
          end
          render xml: @item.to_dls_xml(version)
        end
      end
    end
  end

  private

  ##
  # Authenticates a user via HTTP Basic and authorizes by IP address.
  #
  def authorize_api_user
    authenticate_or_request_with_http_basic do |username, secret|
      config = PearTree::Application.peartree_config
      if username == config[:api_user] and secret == config[:api_secret]
        return config[:api_ips].
            select{ |ip| request.remote_ip.start_with?(ip) }.any?
      end
    end
    false
  end

  def authorize_item
    return unless authorize(@item.collection)
    return unless authorize(@item)
  end

  def check_api_content_type
    if request.content_type != 'application/xml'
      render text: 'Invalid content type.', status: :unsupported_media_type
      return false
    end
    true
  end

  def load_item
    @item = Item.find_by_repository_id(params[:item_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @item
  end

  ##
  # Streams one of an item's bytestreams, or redirects to a bytestream's URL,
  # if it has one.
  #
  # @param item [Item]
  # @param type [Integer] One of the `Bytestream::Type` constants
  # @param disposition [String] `inline` or `attachment`
  #
  def send_bytestream(item, type, disposition)
    disposition = 'attachment' unless %w(attachment inline).include?(disposition)

    bs = item.bytestreams.where(bytestream_type: type).select(&:exists?).first
    if bs
      send_file(bs.absolute_local_pathname, disposition: disposition)
    else
      render status: 404, text: 'Not found.'
    end
  end

  ##
  # The browse context is "what the user is doing" -- needed in item view in
  # order to display appropriate navigational controls, either "back to
  # results" or "back to collection" etc.
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

  def set_files_ivar
    @start = params[:start] ? params[:start].to_i : 0
    @limit = PAGES_LIMIT
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @files = @item.files_from_solr.order(Item::SolrFields::TITLE).
        start(@start).limit(@limit)
  end

  def set_pages_ivar
    @start = params[:start] ? params[:start].to_i : 0
    @limit = PAGES_LIMIT
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @pages = @item.pages_from_solr.order(Item::SolrFields::TITLE).
        start(@start).limit(@limit).to_a
  end

  def using_api?
    request.format == :xml
  end

end
