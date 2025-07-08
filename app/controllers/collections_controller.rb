# frozen_string_literal: true

class CollectionsController < WebsiteController

  LOGGER                  = CustomLogger.new(CollectionsController)
  PERMITTED_SEARCH_PARAMS = [:fq, :id, :q]

  before_action :set_permitted_params, only: :show
  before_action :enable_cors, only: :iiif_presentation
  before_action :set_collection, only: [:iiif_presentation, :show]
  before_action :authorize_collection, only: [:iiif_presentation, :show]

  ##
  # Serves IIIF Presentation API 2.1 collections.
  #
  # Responds to `GET /collections/:id/iiif`
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
  # Responds to `GET /collections/iiif`
  #
  def iiif_presentation_list
    authorize(Collection)
    @collections = Collection.search.
        host_groups(client_host_groups).
        order(CollectionElement.new(name: 'title').indexed_sort_field)

    render 'collections/iiif_presentation_api/index',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # This is a legacy route that used to be served by this application, but now
  # the Metadata Gateway, or whatever it's called, serves it instead.
  #
  # Responds to `GET /collections`
  #
  def index
    authorize(Collection)
    redirect_to ::Configuration.instance.metadata_gateway_url + '/collections',
                status:           301,
                allow_other_host: true
  end

  ##
  # Responds to `GET /collections/:id`
  #
  # N.B.: Unpublished collections are allowed to be shown, but any items
  # residing in them are NOT.
  #
  def show
    @collection_ids = [@collection.repository_id] + @collection.children.pluck(:repository_id)
    @uofi_user = @collection.authorized_by_any_host_groups?(request_context.client_host_groups)
    respond_to do |format|
      format.html do
        @children = []
        if @uofi_user
          @children = Collection.search.
              search_children(true).
              parent_collection(@collection).
              order(CollectionElement.new(name: 'title').indexed_sort_field).
              to_a
          @num_public_objects = @collection.num_public_objects rescue nil
          if @collection.representation_type == Representation::Type::ITEM
            @representative_item = @collection.representative_item
          elsif @collection.representation_type == Representation::Type::MEDUSA_FILE
            bin = Binary.find_by_medusa_uuid(@collection.representative_medusa_file_id)
            @representative_item = bin.item if bin
          end
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
  # Responds to `GET /projects/:alias`.
  #
  # This is a legacy route from `images.library.illinois.edu`.
  #
  def show_contentdm
    col = Collection.where('LOWER(contentdm_alias) = ?',
                           params[:alias].downcase).first
    raise ActiveRecord::RecordNotFound unless col
    redirect_to col
  end


  private

  def authorize_collection
    @collection ? authorize(@collection) : skip_authorization
  end

  def set_collection
    @collection = Collection.find_by_repository_id(params[:collection_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

  def set_permitted_params
    @permitted_params = params.permit(PERMITTED_SEARCH_PARAMS)
  end

end
