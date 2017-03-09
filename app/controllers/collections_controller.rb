class CollectionsController < WebsiteController

  before_action :load_collection, only: [:iiif_presentation, :show]
  before_action :authorize_collection, only: [:iiif_presentation, :show]
  before_action :enable_cors, only: :iiif_presentation

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
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_children(false).
        include_unpublished(false).
        include_unpublished_in_dls(true).
        filter_queries(params[:fq]).
        query(params[:q]).
        order(Collection::SolrFields::TITLE).
        limit(99999)
    @collections = finder.to_a

    # If there are no results, get some search suggestions.
    if @collections.length < 1 and params[:q].present?
      @suggestions = finder.suggestions
    end

    fresh_when(etag: @collections) if Rails.env.production?

    respond_to do |format|
      format.html
      format.js
      format.json do
        render json: @collections.to_a.map { |c|
          { id: c.repository_id, url: collection_url(c) }
        }
      end
    end
  end

  ##
  # Responds to GET /collections/:id
  #
  def show
    fresh_when(etag: @collection) if Rails.env.production?

    respond_to do |format|
      format.html do
        begin
          @representative_image_binary =
              @collection.representative_image_binary
          @is_free_form = (@collection.package_profile ==
              PackageProfile::FREE_FORM_PROFILE)
          # Show the "Browse Folder Tree" button only if the collection is
          # free-form and has no child items.
          @show_browse_tree_button = @is_free_form ?
              (@collection.items.where('parent_repository_id IS NOT NULL').count > 0) : false
        rescue => e
          CustomLogger.instance.error("#{e}")
        end
      end
      format.json { render json: @collection.decorate }
    end
  end

  private

  def authorize_collection
    authorize(@collection)
  end

  def load_collection
    @collection = Collection.find_by_repository_id(params[:collection_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

end
