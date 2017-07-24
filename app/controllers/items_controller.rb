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

  before_action :enable_cors, only: [:iiif_annotation_list, :iiif_canvas,
                                     :iiif_image_resource, :iiif_layer,
                                     :iiif_manifest, :iiif_media_sequence,
                                     :iiif_range, :iiif_sequence]
  before_action :load_item, except: :index
  before_action :authorize_item, except: :index
  before_action :check_published, except: :index
  before_action :set_browse_context, only: :index

  ##
  # Retrieves a binary by its filename.
  #
  # An item shouldn't have multipple binaries with the same filename, but if
  # it does, a random match will be sent.
  #
  # Responds to GET /items/:item_id/binaries/:filename
  #
  def binary
    filename = [params[:filename], params[:format]].join('.')
    binary = @item.binaries.where('repository_relative_pathname LIKE ?',
                                  "%/#{filename}").limit(1).first
    if binary
      send_file(binary.absolute_local_pathname)
    else
      render status: 404, text: 'Binary not found'
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
  # Serves IIIF Presentation API 2.1 annotation lists.
  #
  # Responds to GET /items/:id/list/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#annotation-list
  #
  def iiif_annotation_list
    @annotation_list_name = params[:name]
    if Item.find_by_repository_id(@annotation_list_name)
      render 'items/iiif_presentation_api/annotation_list',
             formats: :json, content_type: 'application/json'
    else
      render text: 'No such annotation list.', status: :not_found
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
  # Serves IIIF Presentation API 2.1 image resources.
  #
  # Responds to GET /items/:id/annotation/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#image-resources
  #
  def iiif_image_resource
    valid_names = %w(access preservation)
    if valid_names.include?(params[:name])
      @image_resource_name = params[:name]
      @binary = @item.iiif_image_binary
      render 'items/iiif_presentation_api/image_resource',
             formats: :json, content_type: 'application/json'
    else
      render text: 'No such image resource.', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 layers.
  #
  # Responds to GET /items/:id/layer/:name
  #
  # @see http://iiif.io/api/presentation/2.1/#layer
  #
  def iiif_layer
    @layer_name = params[:name]
    if Item.find_by_repository_id(@layer_name)
      render 'items/iiif_presentation_api/layer',
             formats: :json, content_type: 'application/json'
    else
      render text: 'No such layer.', status: :not_found
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
           formats: :json, content_type: 'application/json'
  end

  ##
  # Serves media sequences -- an IIIF Presentation API extension by the
  # Wellcome Library that enables the UniversalViewer to work with certain
  # non-image content.
  #
  # Responds to GET /items/:id/xsequence/:name
  #
  # @see https://gist.github.com/tomcrane/7f86ac08d3b009c8af7c
  #
  def iiif_media_sequence
    render 'items/iiif_presentation_api/media_sequence',
           formats: :json, content_type: 'application/json'
  end

  ##
  # Serves IIIF Presentation API 2.1 ranges.
  #
  # Responds to GET /items/:id/range/:name where :name is a subitem repository
  # ID.
  #
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_range
    @subitem = Item.find_by_repository_id(params[:name])
    @item = @subitem.parent
    if @subitem
      render 'items/iiif_presentation_api/range',
             formats: :json,
             content_type: 'application/json'
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
    @limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)
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
        only_described(true).
        stats(true).
        filter_queries(params[:fq]).
        sort(Item::SolrFields::STRUCTURAL_SORT).
        start(params[:download_start]).
        limit(params[:limit] || MedusaDownloaderClient::BATCH_SIZE)
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
        # Use the Medusa Downloader to generate a zip of items from
        # download_finder. It takes the downloader time to generate the zip
        # file manifest, which would block the web server if we did it here
        # (DLD-94), so the strategy is to do it using the asynchronous
        # download feature, and then stream the zip out to the user via the
        # download button when it's ready to start streaming.
        item_ids = download_finder.to_a.map(&:repository_id)

        start = params[:download_start].to_i + 1
        end_ = params[:download_start].to_i + item_ids.length
        zip_name = "items-#{start}-#{end_}"

        download = Download.create
        DownloadZipJob.perform_later(item_ids, zip_name, download)
        redirect_to download_url(download)
      end
    end
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

        # If the item has a parent and variant and the variant is not FILE or
        # DIRECTORY, redirect to its parent. This is to force compound object
        # pages and other child items to be viewed within the context of the
        # object itself.
        if @item.parent and @item.variant and
            ![Item::Variants::DIRECTORY, Item::Variants::FILE].include?(@item.variant)
          redirect_to @item.parent, status: 303
          return
        end

        set_files_ivar

        # Find the previous and next result based on the results URL in the
        # session.
        results_url = session[:browse_context_url]
        if results_url.present?
          uri = URI.parse(results_url)
          query = Rack::Utils.parse_nested_query(uri.query) || {}
          query[:start] = session[:start].to_i if query[:start].blank?
          limit = Option::integer(Option::Keys::RESULTS_PER_PAGE)
          if session[:first_result_id] == @item.repository_id
            query[:start] -= limit / 2.0
          elsif session[:last_result_id] == @item.repository_id
            query[:start] += limit / 2.0
          end
          finder = item_finder_for(query)
          results = finder.to_a
          results.each_with_index do |result, index|
            if result&.repository_id == @item.repository_id
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
      format.zip do
        # See the documentation for format.zip in index().
        #
        # For directories, the zip file will contain content for each
        # file-variant item at any sublevel. For compound objects, it will
        # contain content for each item in the object.
        if @item.variant == Item::Variants::DIRECTORY
          if @item.items.any?
            items = @item.all_files
            zip_name = 'files'
          else
            flash['error'] = 'This directory is empty.'
            redirect_to @item
          end
        else
          items = @item.items.any? ? @item.items : [@item]
          zip_name = 'item'
        end

        item_ids = items.map(&:repository_id)

        download = Download.create
        case params[:contents]
          when 'jpegs'
            CreateZipOfJpegsJob.perform_later(item_ids, zip_name, download)
          else
            DownloadZipJob.perform_later(item_ids, zip_name, download)
        end
        redirect_to download_url(download)
      end
    end
  end

  private

  def authorize_item
    return unless authorize(@item.collection)
    return unless authorize(@item)
  end

  def check_published
    unless @item.published and @item.collection.published
      render 'unpublished', status: :forbidden
    end
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
    session[:collection_id] = query[:collection_id]
    session[:q] = query[:q]
    session[:fq] = query[:fq]
    session[:sort] = query[:sort] if query[:sort].present?
    session[:start] = query[:start].to_i if query[:start].present?
    session[:start] = 0 if session[:start] < 0

    # display=leaves is used in free-form collections to show files flattened.
    if params[:display] == 'leaves'
      ItemFinder.new.
          client_hostname(request.host).
          client_ip(request.remote_ip).
          client_user(current_user).
          collection_id(session[:collection_id]).
          query(session[:q]).
          include_children(true).
          only_described(true).
          include_variants([Item::Variants::FILE]).
          filter_queries(session[:fq]).
          sort(session[:sort]).
          start(session[:start]).
          limit(Option::integer(Option::Keys::RESULTS_PER_PAGE))
    else
      ItemFinder.new.
          client_hostname(request.host).
          client_ip(request.remote_ip).
          client_user(current_user).
          collection_id(session[:collection_id]).
          query(session[:q]).
          include_children(!(@collection and @collection.package_profile == PackageProfile::FREE_FORM_PROFILE)).
          only_described(true).
          exclude_variants(Item::Variants::non_filesystem_variants).
          filter_queries(session[:fq]).
          sort(session[:sort]).
          start(session[:start]).
          limit(Option::integer(Option::Keys::RESULTS_PER_PAGE))
    end
  end

  def load_item
    @item = Item.find_by_repository_id(params[:item_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @item
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
    @files = @item.filesystem_variants_from_solr.
        order({Item::SolrFields::VARIANT => :asc},
              {Item::SolrFields::TITLE => :asc}).
        start(@start).limit(@limit)
  end

end
