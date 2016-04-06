class CollectionsController < WebsiteController

  def index
    @collections = MedusaCollection.all.
        where(MedusaCollection::SolrFields::PUBLISHED => true).
        order(MedusaCollection::SolrFields::TITLE).limit(9999)

    respond_to do |format|
      format.html
      format.json do
        render json: @collections.to_a.map { |c|
          {
              id: c.id,
              url: collection_url(c)
          }
        }
      end
    end
  end

  def show
    @collection = MedusaCollection.find(params[:id])
    unless @collection.published
      render 'error/error', status: :forbidden, locals: {
          status_code: 403,
          status_message: 'Forbidden',
          message: 'This collection is not published.'
      }
    end

    respond_to do |format|
      format.html do
        @representative_item = @collection.representative_item
      end
      format.json { render json: @collection }
    end
  end

end
