class CollectionsController < WebsiteController

  before_action :load_collection, only: :show
  before_action :authorize_collection, only: :show

  def index
    @collections = Collection.solr.
        where(Collection::SolrFields::PUBLISHED => true).
        where(Collection::SolrFields::ACCESS_URL => :not_null).
        facetable_fields(Collection::solr_facet_fields.map{ |e| e[:name] }).
        order(Collection::SolrFields::TITLE).limit(99999)

    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @collections = @collections.facet(fq) }
    else
      @collections = @collections.facet(params[:fq])
    end

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
        @representative_image_bytestream =
            @collection.representative_image_bytestream
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
