class ItemsController < WebsiteController

  include ActionController::Streaming

  class BrowseContext
    BROWSING_ALL_ITEMS = 0
    BROWSING_COLLECTION = 1
    SEARCHING = 2
    FAVORITES = 3
  end

  MAX_RESULT_WINDOW = 100
  MIN_RESULT_WINDOW = 10
  PERMITTED_PARAMS = [:_, :collection_id, :df, :display, :download_start,
                      { fq: [] }, :format, :id, :limit, :q, :sort, :start,
                      :utf8]

  before_action :enable_cors, only: [:iiif_annotation_list, :iiif_canvas,
                                     :iiif_image_resource, :iiif_layer,
                                     :iiif_manifest, :iiif_media_sequence,
                                     :iiif_range, :iiif_sequence]

  before_action :load_item, except: [:index, :tree, :tree_data]
  before_action :authorize_item, except: [:index, :tree, :tree_data]
  before_action :check_publicly_accessible, except: [:index, :tree, :tree_data]
  before_action :set_browse_context, only: :index
  before_action :set_sanitized_params, only: [:index, :show, :tree]

  rescue_from AuthorizationError, with: :rescue_unauthorized
  rescue_from UnpublishedError, with: :rescue_unpublished

  ##
  # Retrieves a binary by its filename.
  #
  # An item shouldn't have multiple binaries with the same filename, but if
  # it does, one of them will be sent at random.
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
      render plain: 'No such annotation list.', status: :not_found
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
      render plain: 'No such canvas.', status: :not_found
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
      @binary = @item.effective_image_binary
      render 'items/iiif_presentation_api/image_resource',
             formats: :json,
             content_type: 'application/json'
    else
      render plain: 'No such image resource.', status: :not_found
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
             formats: :json,
             content_type: 'application/json'
    else
      render plain: 'No such layer.', status: :not_found
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
           formats: :json,
           content_type: 'application/json'
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
      render plain: 'No such range.', status: :not_found
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
          @start_canvas_item = @item.finder.limit(1).first
          render 'items/iiif_presentation_api/sequence',
                 formats: :json,
                 content_type: 'application/json'
        else
          render plain: 'This object does not have an item sequence.',
                 status: :not_found
        end
      when 'page'
        if @item.pages.count > 0
          @start_canvas_item =
              @item.items.where(variant: Variants::TITLE).limit(1).first ||
                  @item.pages.first
          render 'items/iiif_presentation_api/sequence',
                 formats: :json,
                 content_type: 'application/json'
        else
          render plain: 'This object does not have a page sequence.',
                 status: :not_found
        end
      else
        render plain: 'Sequence not available.', status: :not_found
    end
  end

  ##
  # Responds to GET /items
  #
  def index
    if params[:collection_id]
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      # If the collection is unauthorized, redirect to the show-collection
      # page which will contain an explanation.
      begin
        authorize(@collection)
      rescue AuthorizationError
        redirect_to @collection
      end
    end

    finder = item_finder_for(params)
    @items = finder.to_a
    @facets = finder.facets

    @current_page = finder.page
    @count = finder.count
    @start = finder.get_start
    @limit = finder.get_limit
    @num_results_shown = [@limit, @count].min
    @metadata_profile = @collection&.effective_metadata_profile ||
        MetadataProfile.default

    # If there are no results, get some search suggestions.
    if @count < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    @download_finder = ItemFinder.new.
        user_roles(request_roles).
        collection(@collection).
        facet_filters(params[:fq]).
        query_all(params[:q]).
        aggregations(false).
        search_children(true).
        include_children_in_results(true).
        order(Item::IndexFields::STRUCTURAL_SORT).
        start(params[:download_start]).
        limit((params[:limit].to_i > 0) ? params[:limit].to_i : ElasticsearchClient::MAX_RESULT_WINDOW)
    @num_downloadable_items = @download_finder.count
    @total_byte_size = @download_finder.total_byte_size

    respond_to do |format|
      format.html do
        session[:first_result_id] = @items.first&.repository_id
        session[:last_result_id] = @items.last&.repository_id
      end
      format.atom do
        @updated = @items.any? ?
            @items.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.js
      format.json do
        render json: {
            start: @start,
            limit: @limit,
            numResults: @count,
            results: @items.map { |item|
              {
                  id: item.repository_id,
                  uri: item_url(item, format: :json)
              }
            }
          }
      end
      format.zip do
        # Use the Medusa Downloader to generate a zip of items from
        # download_finder. It takes the downloader time to generate the zip
        # file manifest, which would block the web server if we did it here,
        # so the strategy is to do it using the asynchronous download feature,
        # and then stream the zip out to the user via the download button when
        # it's ready to start streaming.
        item_ids = @download_finder.to_a.map(&:repository_id)

        if item_ids.any?
          start = params[:download_start].to_i + 1
          end_ = params[:download_start].to_i + item_ids.length
          zip_name = "items-#{start}-#{end_}"

          download = Download.create(ip_address: request.remote_ip)
          DownloadZipJob.perform_later(item_ids, zip_name, download)
          redirect_to download_url(download)
        else
          flash['error'] = 'No items to download.'
          redirect_back fallback_location: request.fullpath
        end
      end
    end
  end

  ##
  # Responds to GET /items/:id
  #
  def show
    respond_to do |format|
      format.html do
        # Free-form items are handled differently from the rest: different
        # controller ivars, different templates...
        if @item.file? or @item.directory?
          # Only XHR requests are allowed for a file or directory variant.
          # These will generally be in response to a selection in the tree
          # browser and should render either a show-file or show-directory
          # template with no layout.
          if request.xhr?
            download_finder = @item.finder.
                exclude_variants(*Item::Variants::DIRECTORY)
            # If the item is a directory, its contents are downloadable.
            # Otherwise, it's a file and it itself is downloadable.
            @downloadable_items = @item.directory? ?
                                      download_finder.to_a : [@item]
            @total_byte_size = download_finder.total_byte_size

            if params['tree-node-type'].include?('file_node')
              render 'show_file', layout: false
            elsif params['tree-node-type'].include?('directory_node')
              render 'show_directory', layout: false
            end
          # We don't want to send crawler bots to the tree view because it's
          # all dynamic and they won't be able to see anything. So, give them
          # the show template.
          elsif request.user_agent.include?('Twitterbot')
            @root_item = @item
            @downloadable_items = []
            @total_byte_size = 0
            render 'show'
          else
            # Non-XHR requests for free-form items are not allowed. Redirect
            # to the item's HTML representation.
            redirect_to collection_tree_path(@item.collection) + '#' +
                            @item.repository_id
          end
        else
          # DLD-98 calls for the URL in the browser bar to change when an item
          # is selected in the viewer. In other words, each item in the viewer
          # needs to have its own URL and dereferencing it should load the same
          # page with a different viewer item selected. We refer to this item
          # as @selected_item, and nil out @item to prevent confusion.
          @selected_item = @item
          @item = nil

          # @containing_item is the immediate parent of @selected_item. If
          # @selected_item has no parent, @containing_item === @selected_item.
          @containing_item = @selected_item.parent || @selected_item

          # @root_item is the root parent of @selected_item. If @selected_item
          # has no parent, @selected_item === @root_item. @root_item is now the
          # main item that will be displayed in the view.
          @root_item = @selected_item.parent ?
                      @selected_item.root_parent : @selected_item

          # All items within the containing item are downloadable.
          finder = @containing_item.finder
          @total_byte_size = finder.total_byte_size
          @downloadable_items = finder.to_a

          # Find the previous and next result based on the results URL in the
          # session.
          results_url = session[:browse_context_url]
          if results_url.present?
            query = UrlUtil.parse_query(results_url).symbolize_keys
            query[:start] = session[:start].to_i if query[:start].blank?
            limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
            if session[:first_result_id] == @root_item.repository_id
              query[:start] = query[:start].to_i - limit / 2.0
            elsif session[:last_result_id] == @root_item.repository_id
              query[:start] = query[:start].to_i + limit / 2.0
            end
            finder = item_finder_for(query)
            results = finder.to_a
            results.each_with_index do |result, index|
              if result.repository_id == @containing_item.repository_id
                @previous_result = results[index - 1] if index - 1 >= 0
                @next_result = results[index + 1] if index + 1 < results.length
              end
            end

            session[:first_result_id] = results.first&.repository_id
            session[:last_result_id] = results.last&.repository_id
          end
        end
      end
      format.atom
      format.json do
        render json: @item.decorate
      end
      format.pdf do
        # PDF download is only available for compound objects.
        if @item.is_compound?
          download = Download.create(ip_address: request.remote_ip)
          CreatePdfJob.perform_later(@item, download)
          redirect_to download_url(download)
        else
          flash['error'] = 'PDF downloads are only available for compound objects.'
          redirect_to @item
        end
      end
      format.zip do
        # See the documentation for format.zip in index().
        #
        # * For Directory-variant items, the zip file will contain content for
        #   each File-variant item at any sublevel.
        # * For File-variant items that have a Directory-variant parent, the
        #   zip file will contain content for each of the items in the parent.
        # * For File-variant items that don't have a parent, the zip file will
        #   contain content for each of the items in the collection.
        # * For compound objects, the zip file will contain content for each
        #   item in the object.
        #
        # All of the above also have to take authorization into account, and
        # only include authorized content in zip files.
        #
        if @item.directory?
          if @item.items.any?
            items = @item.finder.
                user_roles(request_roles).
                include_variants(*Item::Variants::FILE).
                include_children_in_results(true).to_a
            zip_name = 'files'
          else
            flash['error'] = 'This directory is empty.'
            redirect_to @item
            return
          end
        elsif @item.file?
          if @item.parent
            items = @item.parent.finder.
                user_roles(request_roles).
                include_variants(*Item::Variants::FILE).
                include_children_in_results(true).to_a
          else
            items = ItemFinder.new.
                aggregations(false).
                user_roles(request_roles).
                collection(@item.collection).
                include_variants(*Item::Variants::FILE)
                include_children_in_results(true).to_a
          end
          zip_name = 'files'
        else
          items = @item.finder.
              user_roles(request_roles).
              include_children_in_results(true).to_a + [@item]
          zip_name = 'item'
        end

        item_ids = items.map(&:repository_id)
        if item_ids.any?
          download = Download.create(ip_address: request.remote_ip)
          case params[:contents]
            when 'jpegs'
              CreateZipOfJpegsJob.perform_later(item_ids, zip_name, download)
            else
              DownloadZipJob.perform_later(item_ids, zip_name, download)
          end
          redirect_to download_url(download)
        else
          flash['error'] = 'No items to download.'
          redirect_back fallback_location: request.fullpath
        end
      end
    end
  end

  ##
  # Handles the root of free-form tree view.
  #
  # Responds to GET /collections/:collection_id/tree
  #
  def tree
    if params[:collection_id]
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

    respond_to do |format|
      format.html do
        if @collection.free_form?
          if request.xhr?
            download_finder = ItemFinder.new.
                user_roles(request_roles).
                collection(@collection).
                include_children_in_results(true).
                aggregations(false)
            @num_downloadable_items = download_finder.count
            @total_byte_size = download_finder.total_byte_size
            @num_directories = @collection.items.
                where(variant: Item::Variants::DIRECTORY).count
            @num_files = @collection.items.
                where(variant: Item::Variants::FILE).count
            render 'show_collection_summary', layout: false
          end
        else
          redirect_to collection_items_path
        end
      end
      format.atom do
        redirect_to collection_items_path(format: :atom)
      end
      format.json do
        redirect_to collection_items_path(format: :json)
      end
      format.zip do
        redirect_to collection_items_path(format: :zip, params: @permitted_params)
      end
    end
  end

  ##
  # Returns a JSON representation of a collection's item tree structure, for
  # free-form tree view.
  #
  # Responds to GET /collections/:id/items/treedata
  #
  def tree_data
    @collection = Collection.find_by_repository_id(params[:collection_id])
    raise ActiveRecord::RecordNotFound unless @collection
    authorize(@collection)

    @start = params[:start].to_i
    finder = item_finder_for(params).order(Item::IndexFields::STRUCTURAL_SORT)
    @items = finder.to_a
    tree_data = @items.map { |item| item_tree_hash(item) }

    render json: create_tree_root(tree_data, @collection)
  end

  ##
  # Returns a JSON representation of an item's tree structure, for free-form
  # tree view.
  #
  # Responds to GET /items/:id/treedata
  #
  def item_tree_node
    render json: @item.finder.to_a.map { |child| item_tree_hash(child) }
  end



  private

  def authorize_item
    authorize(@item)
    authorize(@item.collection)
  end

  def item_tree_hash(item)
    num_subitems = item.items.count
    {
        id: item.repository_id,
        text: item.title,
        children: (num_subitems > 0),
        icon: (num_subitems == 0) ? 'jstree_file' : nil,
        a_attr: {
            href: item_path(item),
            class: item.directory? ? 'directory_node Item' : 'file_node Item'
        }
    }
  end

  def create_tree_root(tree_hash_array, collection)
    node_hash = Hash.new
    node_hash['id'] = collection.repository_id
    node_hash['text'] = collection.title
    node_hash['state'] = {opened: true, selected: true}
    # We will check the class in JS to determine what URL to route to
    # (/collections/:id or /items/:id).
    node_hash['a_attr'] = {name: 'root-collection-node',
                           class: 'root-collection-node Collection'}
    node_hash['children'] = tree_hash_array
    node_hash
  end

  def check_publicly_accessible
    raise UnpublishedError unless @item.publicly_accessible?
  end

  ##
  # Returns an ItemFinder for the given query (either params or parsed out of
  # the request URI) and saves its builder arguments to the session. This is
  # so that a similar instance can be constructed in show-item view to enable
  # paging through the results.
  #
  # @param query [ActionController::Parameters, Hash]
  # @return [ItemFinder]
  #
  def item_finder_for(query)
    session[:collection_id] = query[:collection_id]
    session[:q] = query[:q]
    session[:fq] = query[:fq]
    session[:sort] = query[:sort] if query[:sort].present?
    session[:start] = query[:start].to_i
    session[:start] = 0 if session[:start].to_i < 0
    session[:limit] = query[:limit].to_i
    if session[:limit].to_i < MIN_RESULT_WINDOW or
        session[:limit].to_i > MAX_RESULT_WINDOW
      session[:limit] = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
    end

    # display=leaves is used in free-form collections to show files flattened.
    if params[:display] == 'leaves'
      ItemFinder.new.
          user_roles(request_roles).
          collection(Collection.find_by_repository_id(session[:collection_id])).
          facet_filters(session[:fq]).
          query_all(session[:q]).
          search_children(true).
          include_variants(Item::Variants::FILE).
          order(session[:sort]).
          start(session[:start]).
          limit(session[:limit])
    else
      ItemFinder.new.
          user_roles(request_roles).
          collection(Collection.find_by_repository_id(session[:collection_id])).
          facet_filters(session[:fq]).
          query_all(session[:q]).
          search_children(@collection&.package_profile != PackageProfile::FREE_FORM_PROFILE).
          exclude_variants(*Item::Variants::non_filesystem_variants).
          order(session[:sort]).
          start(session[:start]).
          limit(@collection&.free_form? ?
                    ElasticsearchClient::MAX_RESULT_WINDOW : session[:limit])
    end
  end

  def load_item
    @item = Item.find_by_repository_id(params[:item_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @item
  end

  def rescue_unauthorized
    respond_to do |format|
      format.html do
        render 'unauthorized', status: :forbidden
      end
      format.json do
        render 'errors/error', status: :forbidden, locals: {
            message: 'You are not authorized to access this item.'
        }
      end
    end
  end

  def rescue_unpublished
    respond_to do |format|
      format.html do
        render 'unpublished', status: :forbidden
      end
      format.json do
        render 'errors/error', status: :forbidden, locals: {
            message: 'This item is unpublished.'
        }
      end
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

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

end
