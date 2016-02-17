module Admin

  class CollectionDefsController < ControlPanelController

    before_action :update_collections_rbac, only: :update

    def edit
      @collection = Collection.find(params[:id])
      @collection_def = @collection.collection_def

      @metadata_profile_options_for_select = MetadataProfile.order(:name).
          map{ |t| [ t.name, t.id ] }
      @theme_options_for_select = [[ 'None (Use Global)', nil ]] +
          Theme.order(:name).map{ |t| [ t.name, t.id ] }
    end

    def update
      begin
        collection = Collection.find(params[:id])
        @collection_def = collection.collection_def
        @collection_def.update!(sanitized_params)
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Collection \"#{collection.title}\" updated."
        redirect_to admin_collection_path(collection)
      end
    end

    private

    def sanitized_params
      params.require(:collection_def).permit(:id, :metadata_profile_id,
                                             :theme_id)
    end

    def update_collections_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_COLLECTION)
    end

  end

end
