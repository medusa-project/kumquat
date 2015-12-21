module Admin

  class CollectionDefsController < ControlPanelController

    #before_action :delete_rbac, only: :destroy
    #before_action :update_rbac, only: :update

    def destroy
      begin
        @collection_def = Collection.find(params[:id])
        @collection_def.destroy!
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_repository_collection_url(@collection)
      else
        flash['success'] = "Collection \"#{@collection.title}\" deleted."
        redirect_to admin_repository_collections_url
      end
    end

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

    def create_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::CREATE_COLLECTION)
    end

    def delete_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::DELETE_COLLECTION)
    end

    def sanitized_params
      params.require(:collection_def).permit(:id, :metadata_profile_id,
                                             :theme_id)
    end

    def update_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_COLLECTION)
    end

  end

end
