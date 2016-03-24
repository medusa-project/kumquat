module Admin

  class CollectionsController < ControlPanelController

    def index
      @collections = MedusaCollection.all.sort{ |c,d| c.title <=> d.title }
    end

    def show
      @collection = MedusaCollection.find(params[:id])
      @file_group = @collection.collection_def.medusa_file_group_id ?
          @collection.collection_def.medusa_file_group : nil
    end

  end

end
