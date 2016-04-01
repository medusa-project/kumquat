class CollectionsController < WebsiteController

  def index
    @collections = MedusaCollection.all.
        where(MedusaCollection::SolrFields::PUBLISHED => true).
        order(MedusaCollection::SolrFields::TITLE).limit(9999)
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
    @representative_item = @collection.representative_item
  end

end
