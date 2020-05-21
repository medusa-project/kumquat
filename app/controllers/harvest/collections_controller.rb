module Harvest

  class CollectionsController < AbstractHarvestController

    before_action :load_collection

    ##
    # Responds to `GET /harvest/collections/:id`
    #
    def show
      struct              = @collection.as_harvestable_json
      struct[:public_uri] = collection_url(@collection)
      parent              = @collection.parents.first
      struct[:parent]     = { id: parent.repository_id,
                              uri: collection_url(parent) } if parent
      render json: struct
    end

    private

    def load_collection
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

  end

end
