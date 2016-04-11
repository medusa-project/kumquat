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
      ReindexCollectionsJob.perform_later
      flash['success'] = 'Refreshing collections in the background.
        (This will take a minute.)'
      redirect_to :back
    end

    ##
    # Responds to PATCH /admin/collections/:id/reindex
    #
    def reindex
      ReindexCollectionItemsJob.perform_later(params[:collection_id])

      flash['success'] = 'Indexing collection in the background.
        (This will take a while.)'
      redirect_to :back
    end

    def show
      @collection = MedusaCollection.find(params[:id])
      @data_file_group = @collection.collection_def.medusa_data_file_group_id ?
          @collection.collection_def.medusa_data_file_group : nil
      @metadata_file_group = @collection.collection_def.medusa_metadata_file_group_id ?
          @collection.collection_def.medusa_metadata_file_group : nil
      @can_reindex = (@collection.published_in_dls and
          @collection.collection_def.medusa_data_file_group)
    end

  end

end
