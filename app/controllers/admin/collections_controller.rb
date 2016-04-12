module Admin

  class CollectionsController < ControlPanelController

    before_action :update_collections_rbac, only: :update

    def edit
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile_options_for_select = MetadataProfile.order(:name).
          map{ |t| [ t.name, t.id ] }
      @theme_options_for_select = [[ 'None (Use Global)', nil ]] +
          Theme.order(:name).map{ |t| [ t.name, t.id ] }
    end

    def index
      @collections = Collection.solr.order(Collection::SolrFields::TITLE).
          limit(9999)
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
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @data_file_group = @collection.medusa_data_file_group_id ?
          @collection.medusa_data_file_group : nil
      @metadata_file_group = @collection.medusa_metadata_file_group_id ?
          @collection.medusa_metadata_file_group : nil
      @can_reindex = (@collection.published_in_dls and
          @collection.medusa_data_file_group)
    end

    def update
      begin
        collection = Collection.find_by_repository_id(params[:id])
        raise ActiveRecord::RecordNotFound unless collection

        collection.update!(sanitized_params)
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Collection \"#{collection.title}\" updated."
        redirect_to admin_collection_path(collection)
      end
    end

    private

    def sanitized_params
      params.require(:collection).permit(:id, :medusa_data_file_group_id,
                                         :medusa_metadata_file_group_id,
                                         :metadata_profile_id, :theme_id)
    end

    def update_collections_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_COLLECTION)
    end

  end

end
