module Admin

  class CollectionsController < ControlPanelController

    def index
      @collections = MedusaCollection.all.
          order(MedusaCollection::SolrFields::TITLE).limit(9999)
    end

    ##
    # Responds to PATCH /admin/collections/refresh
    #
    def refresh
      MedusaIndexer.new.index_collections
      flash['success'] = 'Collections refreshed.'
      redirect_to :back
    end

    def show
      @collection = MedusaCollection.find(params[:id])
      @data_file_group = @collection.collection_def.medusa_data_file_group_id ?
          @collection.collection_def.medusa_data_file_group : nil
      @metadata_file_group = @collection.collection_def.medusa_metadata_file_group_id ?
          @collection.collection_def.medusa_metadata_file_group : nil
    end

  end

end
