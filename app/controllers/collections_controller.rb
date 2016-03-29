class CollectionsController < WebsiteController

  def index
    @collections = MedusaCollection.all.sort{ |c,d| c.title <=> d.title }.
        select(&:published)
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
