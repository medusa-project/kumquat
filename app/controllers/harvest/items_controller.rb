module Harvest

  class ItemsController < AbstractHarvestController

    before_action :load_item

    ##
    # Responds to `GET /harvest/items/:id`
    #
    def show
      json                  = @item.as_harvestable_json
      json[:public_uri]     = item_url(@item)
      json[:collection_uri] = collection_url(@item.collection, format: :json) if
          @item.collection
      render json: json
    end

    private

    def load_item
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item
    end

  end

end
