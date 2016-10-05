class CollectionsController < WebsiteController

  before_action :load_collection, only: :show
  before_action :authorize_collection, only: :show

  def index
    filters = { Collection::SolrFields::ACCESS_URL => :not_null }
    filters += params[:fq] if params[:fq]

    finder = CollectionFinder.new.
        client_hostname(request.host).
        client_ip(request.remote_ip).
        client_user(current_user).
        include_unpublished(false).
        include_unpublished_in_dls(true).
        filter_queries(filters).
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
    @collection = Collection.find_by_repository_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @collection
  end

end
