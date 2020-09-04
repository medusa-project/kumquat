class CollectionsController < WebsiteController

  LOGGER = CustomLogger.new(CollectionsController)
  PERMITTED_PARAMS = [:_, :fq, :id, :q, :utf8]

  before_action :load_collection, only: [:iiif_presentation, :show]
  before_action :authorize_collection, only: [:iiif_presentation, :show]
  before_action :check_publicly_accessible, only: [:iiif_presentation, :show]
  before_action :enable_cors, only: :iiif_presentation
  before_action :set_sanitized_params, only: :show

  rescue_from AuthorizationError, with: :rescue_unauthorized
  rescue_from UnpublishedError, with: :rescue_unpublished

  ##
  # Serves IIIF Presentation API 2.1 collections.
  #
  # Responds to GET /collections/:id
  #
  # @see http://iiif.io/api/presentation/2.1/#collection
  #
  def iiif_presentation
    render 'collections/iiif_presentation_api/collection',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # Serves an index of IIIF Presentation API collection representations.
  # N.B.: This endpoint is not an official part of the Presentation API.
  #
  # Responds to GET /collections/iiif
  #
  #
  def iiif_presentation_list
    finder = CollectionFinder.new.
        host_groups(client_host_groups).
        order(CollectionElement.new(name: 'title').indexed_sort_field)
    @collections = finder.to_a

    render 'collections/iiif_presentation_api/index',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # This is a legacy route that used to be served by this application, but now
  # the Metadata Gateway serves it instead.
  #
  # Responds to GET /collections
  #
  def index
    redirect_to ::Configuration.instance.metadata_gateway_url + '/collections',
                status: 303
  end

  ##
  # Responds to GET /collections/:id
  #
  # N.B.: Unpublished collections are allowed to be shown, but any items
  # residing in them are NOT.
  #
  def show
    begin
      @uofi_user = true
      authorize_host_group(@collection)
    rescue AuthorizationError
      @uofi_user = false
    end

    respond_to do |format|
      format.html do
        @children = []
        if @uofi_user
          @children = CollectionFinder.new.
              search_children(true).
              parent_collection(@collection).
              order(CollectionElement.new(name: 'title').indexed_sort_field).
              to_a
          @num_public_objects = @collection.num_public_objects rescue nil
          # One or both of these may be nil.
          @representative_image_binary =
              @collection.effective_representative_image_binary
          @representative_item = @collection.effective_representative_item
          # Show the "Browse Folder Tree" button only if the collection is
          # free-form and has no child items.
          @show_browse_tree_button = @collection.free_form? ?
                                         (@collection.items.where('parent_repository_id IS NOT NULL').count > 0) : false
        end
      end
      format.json do
        if @uofi_user
          render json: @collection.decorate
        else
          render plain: '403 Forbidden', status: :forbidden
        end
      end
    end
  end

  ##
  # Responds to GET /projects/:alias.
  #
  # N.B.: This is a route from images.library.illinois.edu, not CONTENTdm.
  #
  def show_contentdm
    col = Collection.where('LOWER(contentdm_alias) = ?',
                           params[:alias].downcase).first
    raise ActiveRecord::RecordNotFound unless col
    redirect_to col
  end

  private

  def authorize_collection
    authorize(@collection)
  end

  def check_publicly_accessible
    raise UnpublishedError unless @collection.publicly_accessible?
  end

  def load_collection
    @collection = Collection.find_by_repository_id(params[:collection_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

  def rescue_unauthorized
    message = "You are not authorized to access this collection."
    respond_to do |format|
      format.html { render "unauthorized", status: :forbidden }
      format.json { render "errors/error", status: :forbidden, locals: { message: message } }
      format.all { render plain: message, status: :forbidden, content_type: "text/plain" }
    end
  end

  def rescue_unpublished
    message = "This collection is unpublished."
    respond_to do |format|
      format.html { render "unpublished", status: :forbidden }
      format.json { render "errors/error", status: :forbidden, locals: { message: message } }
      format.all { render plain: message, status: :forbidden, content_type: "text/plain" }
    end
  end

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

end
