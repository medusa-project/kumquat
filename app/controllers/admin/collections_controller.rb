module Admin

  class CollectionsController < ControlPanelController

    def index
      @collections = MedusaCollection.all.sort{ |c,d| c.title <=> d.title }
    end

    ##
    # Responds to PATCH /admin/collections/refresh
    def refresh
      MedusaCollection.all.each { |c| c.reload }
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
