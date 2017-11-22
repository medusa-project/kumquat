class CollectionsController < WebsiteController

  PERMITTED_PARAMS = [:_, :fq, :id, :q, :utf8]

  before_action :load_collection, only: [:iiif_presentation, :show]
  before_action :authorize_collection, only: [:iiif_presentation, :show]
  before_action :check_published, only: :iiif_presentation
  before_action :enable_cors, only: :iiif_presentation
  before_action :set_sanitized_params, only: [:index, :show]

  rescue_from UnpublishedError, with: :rescue_unpublished

  ##
  # Serves IIIF Presentation API 2.1 collections.
  #
  # Responds to GET /collection/:id
  #
  # @see http://iiif.io/api/presentation/2.1/#collection
  #
  def iiif_presentation
    render 'collections/iiif_presentation_api/collection',
           formats: :json,
           content_type: 'application/json'
  end

  ##
  # Responds to GET /collections
  #
  def index
    finder = CollectionFinder.new.
        user_roles(request_roles).
        facet_filters(params[:fq]).
        query_all(params[:q]).
        order(Collection::IndexFields::TITLE)
    @start = finder.get_start
    @limit = finder.get_limit
    @count = finder.count
    @collections = finder.to_a
    @facets = finder.facets
    @suggestions = finder.suggestions

    respond_to do |format|
      format.html
      format.atom do
        @updated = @collections.any? ?
                       @collections.map(&:updated_at).sort{ |d| d <=> d }.last : Time.now
      end
      format.js
      format.json do
        render json: {
            start: @start,
            limit: @limit,
            numResults: @count,
            results: @collections.map { |col|
              {
                  id: col.repository_id,
                  uri: collection_url(col, format: :json)
              }
            }
        }
      end
    end
  end

  ##
  # Responds to GET /collections/:id
  #
  # N.B.: Unpublished collections are allowed to be shown, but any items
  # residing in them are NOT.
  #
  def show
    respond_to do |format|
      format.html do
        begin
          @num_public_objects = @collection.num_public_objects
          # One or both of these may be nil.
          @representative_image_binary =
              @collection.effective_representative_image_binary
          @representative_item = @collection.effective_representative_item
          # Show the "Browse Folder Tree" button only if the collection is
          # free-form and has no child items.
          @show_browse_tree_button = @collection.free_form? ?
              (@collection.items.where('parent_repository_id IS NOT NULL').count > 0) : false
        rescue => e
          CustomLogger.instance.info("#{e}")
        end
      end
      format.json { render json: @collection.decorate }
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

  def check_published
    raise UnpublishedError unless @ollection.published
  end

  def load_collection
    @collection = Collection.find_by_repository_id(params[:collection_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

  def rescue_unpublished
    render 'unpublished', status: :forbidden
  end

  def set_sanitized_params
    @permitted_params = params.permit(PERMITTED_PARAMS)
  end

end
