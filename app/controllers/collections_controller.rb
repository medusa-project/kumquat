class CollectionsController < WebsiteController

  def index
    @collections = Collection.solr.
        where(Collection::SolrFields::PUBLISHED => true).
        where(Collection::SolrFields::ACCESS_URL => :not_null).
        facetable_fields(Collection::solr_facet_fields.map{ |e| e[:name] }).
        order(Collection::SolrFields::TITLE).limit(9999)

    if params[:fq].respond_to?(:each)
      params[:fq].each { |fq| @collections = @collections.facet(fq) }
    else
      @collections = @collections.facet(params[:fq])
    end

    fresh_when(etag: @collections) if Rails.env.production?

    respond_to do |format|
      format.html
      format.json do
        render json: @collections.to_a.map { |c| # TODO: optimize this
          {
              id: c.repository_id,
              url: collection_url(c)
          }
        }
      end
    end
  end

  def show
    @collection = Collection.find_by_repository_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @collection

    unless @collection.published
      render 'errors/error', status: :forbidden, locals: {
          status_code: 403,
          status_message: 'Forbidden',
          message: 'This collection is not published.'
      }
    end

    fresh_when(etag: @collection) if Rails.env.production?

    respond_to do |format|
      format.html do
        @representative_image_bytestream =
            @collection.representative_image_bytestream
      end
      format.json { render json: @collection.decorate }
    end
  end

end
