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
  before_action :enable_cors, only: [:iiif_annotation, :iiif_canvas,
                                     :iiif_manifest, :iiif_sequence]
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  # Other actions
  before_action :load_item, only: [:access_master_binary, :files,
                                   :iiif_annotation, :iiif_canvas,
                                   :iiif_manifest, :iiif_sequence, :pages,
                                   :preservation_master_binary, :show]
  before_action :authorize_item, only: [:access_master_binary, :files,
                                        :iiif_annotation, :iiif_canvas,
                                        :iiif_manifest, :iiif_sequence, :pages,
                                        :preservation_master_binary]
  before_action :authorize_item, only: :show, unless: :using_api?
  before_action :set_browse_context, only: :index

  ##
  # Retrieves an item's access master binary.
  #
  # Responds to GET /items/:item_id/access-master
  #
  # The default is to send with a Content-Disposition of `attachment`. Supply a
  # `disposition` query variable of `inline` to override.
  #
  def access_master_binary
    send_binary(@item, Binary::Type::ACCESS_MASTER, params[:disposition])
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
  # Serves IIIF Presentation API 2.1 annotations.
  #
  # Responds to GET /items/:id/annotation/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#annotation
  #
  def iiif_annotation
    valid_names = %w(access preservation)
    if valid_names.include?(params[:name])
      @annotation_name = params[:name]
      @binary = @annotation_name == 'access' ?
          @item.access_master_binary : @item.preservation_master_binary
      render 'items/iiif_presentation_api/annotation',
             formats: :json,
             content_type: 'application/json'
    else
      render text: 'No such annotation.', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 canvases.
  #
  # Responds to GET /items/:id/canvas/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#canvas
  #
  def iiif_canvas
    @page = Item.find_by_repository_id(params[:item_id])
    if @page
      render 'items/iiif_presentation_api/canvas',
             formats: :json,
             content_type: 'application/json'
    else
      render text: 'No such canvas.', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 manifests.
  #
  # Responds to GET /items/:id/manifest
  #
  # @see http://iiif.io/api/presentation/2.1/#manifest
  #
  def iiif_manifest
    render 'items/iiif_presentation_api/manifest',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # Serves IIIF Presentation API 2.1 ranges.
  #
  # Responds to GET /items/:id/range/:name where :name is a value of an
  # Item::Variants constant.
  #
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_range
    all_ranges = Item::Variants::all
    if all_ranges.include?(params[:name])
      @range = params[:name]
      @item = Item.find_by_repository_id(params[:item_id])
      if @item
        render 'items/iiif_presentation_api/range',
               formats: :json,
               content_type: 'application/json'
      else
        render text: 'No such item.', status: :not_found
      end
    else
      render text: 'No such range.', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 sequences.
  #
  # Responds to GET /items/:id/sequence/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#sequence
  #
  def iiif_sequence
    @sequence_name = params[:name]
    case @sequence_name
      when 'item'
        if @item.items.count > 0
          @start_canvas_item = @item.items.first
          render 'items/iiif_presentation_api/sequence',
                 formats: :json,
                 content_type: 'application/json'
        else
          render text: 'This object does not have an item sequence.',
                 status: :not_found
        end
      when 'page'
        if @item.pages.count > 0
          @start_canvas_item = @item.title_item || @item.pages.first
          render 'items/iiif_presentation_api/sequence',
                 formats: :json,
                 content_type: 'application/json'
        else
          render text: 'This object does not have a page sequence.',
                 status: :not_found
        end
      else
        render text: 'Sequence not available.', status: :not_found
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
    params[:start] = @start
    @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
    finder = item_finder_for(params)
    @items = finder.to_a

    @current_page = finder.page
    @count = finder.count
    @num_results_shown = [@limit, @count].min
    @metadata_profile = finder.effective_metadata_profile

    # If there are no results, get some search suggestions.
    if @count < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    download_finder = ItemFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        collection_id(params[:collection_id]).
        query(params[:q]).
        include_children(true).
        stats(true).
        filter_queries(params[:fq]).
        sort(Item::SolrFields::GROUPED_SORT).
        start(params[:download_start]).
        limit(params[:limit] || DownloaderClient::BATCH_SIZE)
    @num_downloadable_items = download_finder.count
    @total_byte_size = download_finder.total_byte_size

    respond_to do |format|
      format.atom do
        @updated = @items.any? ?
            @items.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.html do
        fresh_when(etag: @items) if Rails.env.production?
        session[:first_result_id] = @items.first&.repository_id
        session[:last_result_id] = @items.last&.repository_id
      end
      format.js
      format.json do
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
        items = download_finder.to_a

        client = DownloaderClient.new
        start = params[:download_start].to_i + 1
        end_ = params[:download_start].to_i + items.length
        zip_name = "items-#{start}-#{end_}"
        begin
          download_url = client.download_url(items, zip_name)
        rescue => e
          flash['error'] = "#{e}"
          redirect_to :back
        else
          redirect_to download_url, status: 303
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
  # Retrieves an item's preservation master binary.
  #
  # Responds to GET /items/:id/preservation-master
  #
  # The default is to send with a Content-Disposition of `attachment`. Supply a
  # `disposition` query variable of `inline` to override.
  #
  def preservation_master_binary
    send_binary(@item, Binary::Type::PRESERVATION_MASTER,
                params[:disposition])
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

        if @item.variant == Item::Variants::PAGE
          render 'errors/error', status: :forbidden, locals: {
              status_code: 403,
              status_message: 'Forbidden',
              message: 'This item is an object page.'
          }
          return
        end

        set_files_ivar
        if @files.total_length == 0
          set_pages_ivar
        end

        # Find the previous and next result based on the results URL in the
        # session.
        results_url = session[:browse_context_url]
        if results_url.present?
          uri = URI.parse(results_url)
          query = Rack::Utils.parse_nested_query(uri.query) || {}
          query[:start] = session[:start].to_i if query[:start].blank?
          limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
          if session[:first_result_id] == @item.repository_id
            query[:start] -= limit / 2.0
          elsif session[:last_result_id] == @item.repository_id
            query[:start] += limit / 2.0
          end
          finder = item_finder_for(query)
          results = finder.to_a
          results.each_with_index do |result, index|
            if result.repository_id == @item.repository_id
              @previous_result = results[index - 1] if index - 1 >= 0
              @next_result = results[index + 1] if index + 1 < results.length
            end
          end

          session[:first_result_id] = results.first&.repository_id
          session[:last_result_id] = results.last&.repository_id
        end
      end
      format.json do
        render json: @item.decorate(context: { web: true })
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
      format.zip do # Used for downloading pages into a zip file.
        client = DownloaderClient.new
        begin
          items = @item.items.any? ? @item.items : [@item]
          download_url = client.download_url(items, 'item')
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
  # Authenticates a user via HTTP Basic and authorizes by IP address.
  #
  def authorize_api_user
    authenticate_or_request_with_http_basic do |username, secret|
      config = ::Configuration.instance
      if username == config.api_user and secret == config.api_secret
        return config.api_ips.select{ |ip| request.remote_ip.start_with?(ip) }.any?
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

  ##
  # Returns an ItemFinder for the given query (either params or parsed out of
  # the request URI) and saves its builder arguments to the session. This is
  # so that a similar instance can be constructed in show-item view to enable
  # paging through the results.
  #
  # @param query [ActionController::Parameters,Hash]
  # @return [ItemFinder]
  #
  def item_finder_for(query)
    session[:collection_id] = query[:collection_id] if query[:collection_id].present?
    session[:q] = query[:q]
    session[:fq] = query[:fq]
    session[:sort] = query[:sort] if query[:sort].present?
    session[:start] = query[:start].to_i if query[:start].present?
    session[:start] = 0 if session[:start] < 0

    ItemFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        collection_id(session[:collection_id]).
        query(session[:q]).
        include_children(session[:q].present?).
        exclude_variants([Item::Variants::FRONT_MATTER, Item::Variants::INDEX,
                          Item::Variants::KEY, Item::Variants::PAGE,
                          Item::Variants::TABLE_OF_CONTENTS,
                          Item::Variants::TITLE]).
        filter_queries(session[:fq]).
        sort(session[:sort]).
        start(session[:start]).
        limit(Option::integer(Option::Key::RESULTS_PER_PAGE))
  end

  def load_item
    @item = Item.find_by_repository_id(params[:item_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @item
  end

  ##
  # Streams one of an item's binaries, or redirects to a binary's URL, if it
  # has one.
  #
  # @param item [Item]
  # @param type [Integer] One of the `Binary::Type` constants
  # @param disposition [String] `inline` or `attachment`
  #
  def send_binary(item, type, disposition)
    disposition = 'attachment' unless %w(attachment inline).include?(disposition)

    bs = item.binaries.where(binary_type: type).select(&:exists?).first
    if bs
      send_file(bs.absolute_local_pathname, disposition: disposition)
    else
      render status: 404, text: 'Not found.'
    end
  end

  ##
  # The browse context is "what the user is doing" -- needed in item view in
  # order to display appropriate navigational controls, such as "back to
  # results" or "next item" etc.
  #
  def set_browse_context
    session[:browse_context_url] = request.url
    if params[:q].present? and params[:collection_id].blank?
      session[:browse_context] = BrowseContext::SEARCHING
    elsif params[:collection_id].blank?
      session[:browse_context] = BrowseContext::BROWSING_ALL_ITEMS
    else
      session[:browse_context] = BrowseContext::BROWSING_COLLECTION
    end
  end

  def set_files_ivar
    @start = params[:start] ? params[:start].to_i : 0
    @limit = PAGES_LIMIT
    @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    @files = @item.files_from_solr.
        order({Item::SolrFields::VARIANT => :asc},
              {Item::SolrFields::TITLE => :asc}).
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
