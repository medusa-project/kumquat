class ItemsController < WebsiteController

  include ActionController::Streaming

  class BrowseContext
    BROWSING_ALL_ITEMS  = 0
    BROWSING_COLLECTION = 1
    SEARCHING           = 2
  end

  PERMITTED_SEARCH_PARAMS = [:_, :collection_id, :df, :display, :download_start,
                             { fq: [] }, :field, :format, :id, :limit, :q,
                             :sort, :start]

  before_action :enable_cors, only: [:iiif_annotation_list, :iiif_canvas,
                                     :iiif_image_resource, :iiif_layer,
                                     :iiif_manifest, :iiif_media_sequence,
                                     :iiif_range, :iiif_search, :iiif_sequence]
  before_action :set_item, except: [:index, :tree, :tree_data]
  before_action :set_collection, only: [:index, :tree, :tree_data]
  before_action :authorize_collection, only: [:index, :tree, :tree_data]
  before_action :authorize_item, except: [:index, :tree, :tree_data]
  before_action :set_browse_context, only: :index
  before_action :set_permitted_params, only: [:index, :show, :tree]

  ##
  # Retrieves a binary by its filename.
  #
  # An item shouldn't have multiple binaries with the same filename, but if
  # it does, one of them will be sent at random.
  #
  # Responds to `GET /items/:item_id/binaries/:filename`
  #
  def binary
    parts    = [params[:filename]]
    parts    << params[:format] if params[:format]
    filename = parts.join('.')
    binary   = @item.binaries.where('object_key LIKE ?',
                                    "%/#{filename}").limit(1).first
    if binary
      redirect_to binary_stream_path(binary), status: :moved_permanently
    else
      render plain: 'Binary not found', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 annotation lists.
  #
  # Responds to `GET /items/:item_id/annotation-list/:name`
  #
  # @see http://iiif.io/api/presentation/2.1/#annotation-list
  #
  def iiif_annotation_list
    @annotation_list_name = params[:name]
    if Item.find_by_repository_id(@annotation_list_name)
      render 'items/iiif_presentation_api/annotation_list',
             formats: :json,
             content_type: 'application/json'
    else
      render plain: 'No such annotation list.', status: :not_found
    end
  end

  ##
  # Serves IIIF Presentation API 2.1 canvases.
  #
  # Responds to `GET /items/:item_id/canvas/:name`
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
  # Responds to `GET /items/:item_id/annotation/:name`
  #
  # @see http://iiif.io/api/presentation/2.1/#image-resources
  #
  def iiif_image_resource
    valid_names = %w(access preservation)
    if valid_names.include?(params[:name])
      @image_resource_name = params[:name]
      @binary              = @item.effective_image_binary
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
  # Responds to `GET /items/:item_id/layer/:name`
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
  # Responds to `GET /items/:item_id/manifest`
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
  # Responds to `GET /items/:item_id/xsequence/:name`
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
  # Responds to `GET /items/:item_id/range/:name` where `:name` is a subitem
  # repository ID.
  #
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_range
    @subitem = Item.find_by_repository_id(params[:name])
    @item    = @subitem.parent
    if @item && @subitem
      render 'items/iiif_presentation_api/range',
             formats: :json,
             content_type: 'application/json'
    else
      render plain: 'No such range.', status: :not_found
    end
  end

  ##
  # Provides an IIIF Search API endpoint which searches within the given item
  # and all child items.
  #
  # Responds to `GET /items/:item_id/manifest/search`.
  #
  def iiif_search
    if params[:q].blank?
      render plain: "Missing query argument (?q=)",
             status: :bad_request and return
    end
    @items = @item.compound? ? @item.search_children : @item.search_self
    @items.query(Item::IndexFields::FULL_TEXT, params[:q])

    # Restricted and unpublished items must be included to make this feature
    # work for restricted items. A signed-in User could theoretically search
    # within someone else's restricted item if they have its UUID, but this
    # seems a very low risk.
    @items.include_unpublished(true) if current_user
    render 'items/iiif_search_api/search',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # Serves IIIF Presentation API 2.1 sequences.
  #
  # Responds to `GET /items/:item_id/sequence/:name`
  #
  # @see http://iiif.io/api/presentation/2.1/#sequence
  #
  def iiif_sequence
    @sequence_name = params[:name]
    case @sequence_name
      when 'item'
        if @item.items.count > 0
          @start_canvas_item = @item.search_children.limit(1).first
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
              @item.items.where(variant: Item::Variants::TITLE).limit(1).first ||
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
  # Responds to `GET /items` and `GET /collections/:collection_id/items`.
  # The former is only allowed for searches (namely of metadata values) and
  # will redirect to the Gateway items path via HTTP 301 unless a `q` query
  # argument is present.
  #
  def index
    authorize(Item)
    if !@collection && params[:q].blank?
      # We are not allowed to access /items without a query. /items is an
      # application-wide search endpoint, and we would prefer to direct users
      # to the Search Gateway. We use a temporary redirect, as this route is
      # still active when a query is provided.
      redirect_to ::Configuration.instance.metadata_gateway_url + '/items',
                  status: :temporary_redirect,
                  allow_other_host: true
      return
    end

    relation           = item_relation_for(params)
    @items             = relation.to_a
    @facets            = relation.facets
    @current_page      = relation.page
    @count             = relation.count
    @start             = relation.get_start
    @limit             = relation.get_limit
    @es_request_json   = relation.request_json
    @es_response_json  = relation.response_json
    @num_results_shown = [@limit, @count].min
    @metadata_profile  = @collection&.effective_metadata_profile ||
        MetadataProfile.default

    # If there are no results, get some search suggestions.
    if @count < 1 && params[:q].present?
      @suggestions = relation.suggestions
    end

    download_relation = Item.search.
        host_groups(client_host_groups).
        collection(@collection).
        facet_filters(params[:fq]).
        aggregations(false).
        search_children(true).
        include_children_in_results(true).
        order(Item::IndexFields::STRUCTURAL_SORT).
        start(params[:download_start]).
        limit(0)
    if params[:field]
      download_relation.query(params[:field], params[:q], true)
    else
      download_relation.query_all(params[:q])
    end
    @num_downloadable_items = download_relation.count
    @total_byte_size        = download_relation.total_byte_size

    
    respond_to do |format|
      format.html do
        session[:first_result_id] = @items.first&.repository_id
        session[:last_result_id]  = @items.last&.repository_id
      end
      format.atom do
        @updated = @items.any? ?
            @items.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.js
      format.json do
        render json: {
            start:      @start,
            limit:      @limit,
            numResults: @count,
            results:    @items.map { |item|
              {
                  id:  item.repository_id,
                  uri: item_url(item, format: :json)
              }
            }
          }
      end
      format.zip do
        return unless check_item_captcha
        download_relation.limit((params[:limit].to_i > 0) ?
                                  params[:limit].to_i : OpensearchClient::MAX_RESULT_WINDOW)
        # Use the Medusa Downloader to generate a zip of items from
        # download_relation. It takes the downloader time to generate the zip
        # file manifest, which would block the web server if we did it here,
        # so the strategy is to do it using the asynchronous download feature.
        item_ids = download_relation.to_a.map(&:repository_id)
        if item_ids.any?
          start    = params[:download_start].to_i 
          end_     = params[:download_start].to_i + item_ids.length - 1
          zip_name = "items-#{start + 1}-#{end_ + 1}"
          download = Download.create(ip_address: request.remote_ip)
          DownloadZipJob.perform_later(item_ids:                 item_ids,
                                       zip_name:                 zip_name,
                                       include_private_binaries: current_user&.medusa_user?,
                                       download:                 download)
          redirect_to download_url(download, format: :json) and return
        else
          flash['error'] = 'No items to download.'
          redirect_back fallback_location: request.fullpath
        end
      end
    end
  end

  ##
  # Responds to `GET /items/:id`
  #
  def show
    if @item.restricted
      render 'show_restricted' and return
    end

    respond_to do |format|
      format.html do
        # Free-form items are handled differently from the rest: different
        # controller ivars, different templates...
        if @item.file? || @item.directory?
          # Only XHR requests are allowed for a file or directory variant.
          # These will generally be in response to a selection in the tree
          # browser and should render either a show-file or show-directory
          # template with no layout.
          if request.xhr?
            download_relation = @item.search_children.
                exclude_variants(*Item::Variants::DIRECTORY)
            # If the item is a directory, its contents are downloadable.
            # Otherwise, it's a file and it itself is downloadable.
            @downloadable_items  = @item.directory? ?
                                     download_relation.to_a : [@item]
            @total_byte_size     = download_relation.total_byte_size
            @show_zip_of_masters = @item.directory?
            @show_zip_of_jpegs   = @show_pdf = false

            if params['tree-node-type']&.include?('file_node')
              render 'show_file', layout: false
            elsif params['tree-node-type']&.include?('directory_node')
              render 'show_directory', layout: false
            else
              render plain: 'Missing tree-node-type argument',
                     status: :bad_request
            end
          elsif false
            # TODO: modify the above clause to check for crawler bots, because
            # the tree view is all dynamic and most of them won't be able to
            # see anything
            @root_item          = @item
            @downloadable_items = []
            @total_byte_size    = 0
            render 'show'
          else
            # Non-XHR requests for free-form items are not allowed. Redirect
            # to the item's HTML representation.
            redirect_to collection_tree_path(@item.collection) + '#' +
                            @item.repository_id and return
          end
        else
          # DLD-98 calls for the URL in the browser bar to change when an item
          # is selected in the viewer. In other words, each item in the viewer
          # needs to have its own URL and dereferencing it should load the same
          # page with a different viewer item selected. We refer to this item
          # as @selected_item, and nil out @item to prevent confusion.
          @selected_item = @item
          @item          = nil

          # @containing_item is the immediate parent of @selected_item. If
          # @selected_item has no parent, @containing_item === @selected_item.
          @containing_item = @selected_item.parent || @selected_item

          # @root_item is the root parent of @selected_item. If @selected_item
          # has no parent, @selected_item === @root_item. @root_item is now the
          # main item that will be displayed in the view.
          @root_item = @selected_item.parent ?
                      @selected_item.root_parent : @selected_item

          # All items within the containing item are downloadable.
          relation            = @containing_item.search_children
          @total_byte_size    = relation.total_byte_size
          @downloadable_items = relation.to_a

          # Determine which, if any, of the various download buttons should
          # appear.
          if @root_item.compound?
            binaries = @root_item.all_child_binaries
            binaries = binaries.where(public: true) unless current_user&.medusa_user?
            @show_zip_of_masters = binaries.count > 0
            if @show_zip_of_masters
              binaries = binaries.where(media_category: Binary::MediaCategory::IMAGE)
              @show_zip_of_jpegs = @show_pdf = binaries.count > 0
            end
          else # single-item object
            @show_zip_of_masters = false
            @show_zip_of_jpegs   = false
            @show_pdf            = false
          end

          # Find the previous and next result based on the results URL in the
          # session.
          results_url = session[:browse_context_url]
          if results_url.present?
            query = UrlUtils.parse_query(results_url).symbolize_keys
            query[:start] = session[:start].to_i if query[:start].blank?
            limit = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
            if session[:first_result_id] == @root_item.repository_id
              query[:start] = query[:start].to_i - limit / 2.0
            elsif session[:last_result_id] == @root_item.repository_id
              query[:start] = query[:start].to_i + limit / 2.0
            end
            relation  = item_relation_for(query)
            results = relation.to_a
            results.each_with_index do |result, index|
              if result.repository_id == @containing_item.repository_id
                @previous_result = results[index - 1] if index - 1 >= 0
                @next_result     = results[index + 1] if index + 1 < results.length
              end
            end
            session[:first_result_id] = results.first&.repository_id
            session[:last_result_id]  = results.last&.repository_id
          end
        end
      end
      format.atom
      format.json do
        render json: @item.decorate
      end
      format.pdf do
        return unless check_item_captcha
        if !@item.compound?
          flash['error'] = 'PDF downloads are only available for compound objects.'
          redirect_to @item and return
        elsif !@item.collection&.publicize_binaries
          flash['error'] = 'This collection\'s binaries are not publicized.'
          redirect_to @item and return
        end
        download = Download.create(ip_address: request.remote_ip)
        CreatePdfJob.perform_later(item:                     @item,
                                   include_private_binaries: current_user&.medusa_user?,
                                   download:                 download)
        redirect_to download_url(download, format: :json) and return
      end
      format.zip do
        return unless check_item_captcha
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
            items = [@item]
            zip_name = 'files'
          else
            flash['error'] = 'This directory is empty.'
            redirect_to @item and return
          end
        elsif @item.file?
          if @item.parent
            items = @item.parent.search_children.
                host_groups(client_host_groups).
                include_variants(*Item::Variants::FILE).
                include_restricted(false).
                to_a
          else
            items = Item.search.
                aggregations(false).
                host_groups(client_host_groups).
                collection(@item.collection).
                include_variants(*Item::Variants::FILE).
                include_children_in_results(true).
                to_a
          end
          zip_name = 'files'
        else
          item  = @item.parent || @item
          items = item.search_children.
              include_restricted(false).
              host_groups(client_host_groups).
              to_a
          items += [item] if !items.include?(item)
          zip_name = 'item'
        end

        item_ids = items.map(&:repository_id)
        if item_ids.any?
          download = Download.create(ip_address: request.remote_ip)

          start_index = params[:download_start].to_i 
          limit = params[:limit].to_i

          if limit > 0
            end_index = [start_index + limit - 1, item_ids.length - 1].min 
            batch_item_ids = item_ids[start_index..end_index]

            zip_name = "items-#{start_index + 1}-#{end_index + 1}"
            
          else
            batch_item_ids = item_ids
          end

          if params[:contents]&.match?(/jpegs/)
            CreateZipOfJpegsJob.perform_later(item_ids:                 item_ids,
                                              zip_name:                 zip_name,
                                              include_private_binaries: current_user&.medusa_user?,
                                              download:                 download)
          else
            DownloadZipJob.perform_later(item_ids:                 batch_item_ids,
                                         zip_name:                 zip_name,
                                         include_private_binaries: current_user&.medusa_user?,
                                         download:                 download)
          end
          redirect_to download_url(download, format: :json) and return
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
  # Responds to `GET /collections/:collection_id/tree`
  #
  def tree
    respond_to do |format|
      format.html do
        if @collection.free_form?
          if request.xhr?
            download_relation = Item.search.
                host_groups(client_host_groups).
                collection(@collection).
                include_children_in_results(true).
                aggregations(false)
            @num_downloadable_items = download_relation.count
            @total_byte_size        = download_relation.total_byte_size
            @num_directories        = @collection.items.
                where(variant: Item::Variants::DIRECTORY).count
            @num_files              = @collection.items.
                where(variant: Item::Variants::FILE).count
            render 'show_collection_summary', layout: false
          end
        else
          redirect_to collection_items_path and return
        end
      end
      format.atom do
        redirect_to collection_items_path(format: :atom)
      end
      format.json do
        redirect_to collection_items_path(format: :json)
      end
      format.zip do
        redirect_to collection_items_path(format: :zip,
                                          params: params.to_unsafe_h)
      end
    end
  end

  ##
  # Returns a JSON representation of a collection's item tree structure, for
  # free-form tree view.
  #
  # Responds to `GET /collections/:id/items/treedata`
  #
  def tree_data
    @start    = params[:start].to_i
    relation  = item_relation_for(params).order(Item::IndexFields::STRUCTURAL_SORT)
    @items    = relation.to_a
    tree_data = @items.map { |item| item_tree_hash(item) }

    render json: create_tree_root(tree_data, @collection)
  end

  ##
  # Returns a JSON representation of an item's tree structure, for free-form
  # tree view.
  #
  # Responds to `GET /items/:id/treedata`
  #
  def item_tree_node
    render json: @item.search_children.to_a.map { |child| item_tree_hash(child) }
  end


  private

  def authorize_item
    @item ? authorize(@item) && authorize(@item.collection) : skip_authorization
  end

  def item_tree_hash(item)
    num_subitems = item.items.count
    {
        id:       item.repository_id,
        text:     item.title,
        children: (num_subitems > 0),
        icon:     (num_subitems == 0) ? 'jstree-file' : nil,
        a_attr: {
            href:  item_path(item),
            class: item.directory? ? 'directory_node Item' : 'file_node Item',
            title: item.title
        }
    }
  end

  def create_tree_root(tree_hash_array, collection)
    node_hash             = {}
    node_hash['id']       = collection.repository_id
    node_hash['text']     = collection.title
    node_hash['state']    = {opened: true, selected: true}
    # We will check the class in JS to determine what URL to route to
    # (/collections/:id or /items/:id).
    node_hash['a_attr']   = {name: 'root-collection-node',
                             class: 'root-collection-node Collection',
                             title: node_hash['text']}
    node_hash['children'] = tree_hash_array
    node_hash
  end

  ##
  # Returns an {ItemRelation} for the given query (either params or parsed out
  # of the request URI) and saves its builder arguments to the session. This is
  # so that a similar instance can be constructed in show-item view to enable
  # paging through the results.
  #
  # @param query [ActionController::Parameters, Hash]
  # @return [ItemRelation]
  #
  def item_relation_for(query)
    session[:collection_id] = query[:collection_id]
    session[:field]         = query[:field]
    session[:q]             = query[:q]
    session[:fq]            = query[:fq]
    session[:sort]          = query[:sort]
    session[:start]         = [0, query[:start].to_i].max
    session[:limit]         = query[:limit].to_i
    if session[:limit] < MIN_RESULT_WINDOW || session[:limit] > MAX_RESULT_WINDOW
      session[:limit] = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
    end

    sort = session[:sort]
    if sort.blank? and @collection
      el = @collection.metadata_profile&.default_sortable_element
      sort = el.indexed_sort_field if el
    end

    relation = Item.search.
        host_groups(client_host_groups).
        collection(@collection).
        facet_filters(session[:fq]).
        order(sort).
        start(session[:start])

    # Return results flattened if not viewing a file tree.
    if @collection&.free_form? && action_name != "tree_data"
      relation.search_children(true).
        include_variants(Item::Variants::FILE).
        limit(session[:limit])
    else
      relation.search_children(@collection&.package_profile != PackageProfile::FREE_FORM_PROFILE).
        exclude_variants(*Item::Variants::non_filesystem_variants).
        limit(@collection&.free_form? ?
                OpensearchClient::MAX_RESULT_WINDOW : session[:limit])
    end

    # `field` is present when searching for identical values in the same
    # metadata element (i.e. when the search button next to a metadata value
    # in show-item view is clicked).
    if session[:field]
      relation.query(session[:field], session[:q], true)
    else
      relation.query_all(session[:q])
    end
    relation
  end

  def set_collection
    if params[:collection_id]
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
    end
  end

  def authorize_collection
    return unless @collection
    authorize(@collection, policy_class: CollectionPolicy,
              policy_method: :show?)
  rescue NotAuthorizedError
    redirect_to @collection
  end

  def set_item
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
    if params[:q].present? && params[:collection_id].blank?
      session[:browse_context] = BrowseContext::SEARCHING
    elsif params[:collection_id].blank?
      session[:browse_context] = BrowseContext::BROWSING_ALL_ITEMS
    else
      session[:browse_context] = BrowseContext::BROWSING_COLLECTION
    end
  end

  def set_permitted_params
    @permitted_params = params.permit(PERMITTED_SEARCH_PARAMS)
  end

end
