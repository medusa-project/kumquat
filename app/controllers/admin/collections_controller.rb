module Admin

  class CollectionsController < ControlPanelController

    before_action :update_collections_rbac, only: :update

    def edit
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile_options_for_select = MetadataProfile.all.order(:name).
          map{ |t| [ t.name, t.id ] }
      @content_profile_options_for_select = ContentProfile.all.
          map{ |t| [ t.name, t.id ] }
      @theme_options_for_select = [[ 'None (Use Global)', nil ]] +
          Theme.order(:name).map{ |t| [ t.name, t.id ] }
    end

    def index
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @start = params[:start] ? params[:start].to_i : 0

      @collections = Collection.solr.order(Collection::SolrFields::TITLE).limit(@limit)
      if params[:q].present?
        @collections.where("#{Collection::SolrFields::TITLE}:*#{params[:q]}*")
      else
        @collections.start(@start)
      end
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
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

    def show
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @file_group = @collection.medusa_file_group_id ?
          @collection.medusa_file_group : nil
      @can_reindex = (@collection.published_in_dls and
          @collection.medusa_file_group)
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
      params.require(:collection).permit(:content_profile_id, :id,
                                         :medusa_cfs_directory_id,
                                         :medusa_file_group_id,
                                         :metadata_profile_id,
                                         :published_in_dls, :theme_id)
    end

    def update_collections_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_COLLECTION)
    end

  end

end
