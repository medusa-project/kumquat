module Harvest

  class ItemsController < AbstractHarvestController

    before_action :load_item

    ##
    # Responds to GET /harvest/items/:id
    #
    def show
      render json: @item.decorate
    end

    private

    def load_item
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item
    end

  end

end
