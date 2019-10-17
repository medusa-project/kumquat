module Harvest

  class CollectionsController < AbstractHarvestController

    before_action :load_collection

    ##
    # Responds to GET /harvest/collections/:id
    #
    def show
      render json: @collection.decorate
    end

    private

    def load_collection
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

  end

end
