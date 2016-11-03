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
    filters = []
    if params[:fq].present?
      if params[:fq].respond_to?(:each)
        filters += params[:fq]
      else
        filters << params[:fq]
      end
    end

    finder = CollectionFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_children(false).
        include_unpublished(false).
        include_unpublished_in_dls(true).
        filter_queries(filters).
        query(params[:q]).
        order(Collection::SolrFields::TITLE).
        limit(99999)
    @collections = finder.to_a

    fresh_when(etag: @collections) if Rails.env.production?

    respond_to do |format|
      format.html
      format.json do
        render json: @collections.to_a.map do |c|
          { id: c.repository_id, url: collection_url(c) }
        end
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
          @representative_image_bytestream =
              @collection.representative_image_bytestream
        rescue => e
          Rails.logger.error("#{e}")
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
