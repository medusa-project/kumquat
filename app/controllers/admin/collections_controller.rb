module Admin

  class CollectionsController < ControlPanelController

    before_action :update_collections_rbac, only: :update

    def edit
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile_options_for_select = MetadataProfile.all.order(:name).
          map{ |t| [ t.name, t.id ] }
      @package_profile_options_for_select = PackageProfile.all.
          map{ |t| [ t.name, t.id ] }
    end

    def index
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @start = params[:start] ? params[:start].to_i : 0

      @collections = Collection.solr.order(Collection::SolrFields::TITLE).limit(@limit)
      if params[:q].present?
        where = "*#{params[:q].gsub(' ', '\\ *')}*" # gsub escapes spaces properly
        @collections.where("#{Collection::SolrFields::TITLE}:#{where}")
      else
        @collections.start(@start)
      end
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
    end

    def show
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @file_group = @collection.medusa_file_group_id.present? ?
          @collection.medusa_file_group : nil
      @can_reindex = (@collection.published_in_dls and
          @collection.medusa_file_group)
    end

    ##
    # Responds to PATCH /admin/collections/sync
    #
    def sync
      SyncCollectionsJob.perform_later
      flash['success'] = 'Syncing collections in the background.
        (This will take a minute.)'
      redirect_to :back
    end

    def update
      begin
        collection = Collection.find_by_repository_id(params[:id])
        raise ActiveRecord::RecordNotFound unless collection

        collection.update!(sanitized_params)
      rescue => e
        flash['error'] = "#{e}"
        redirect_to edit_admin_collection_path(collection)
      else
        flash['success'] = "Collection \"#{collection.title}\" updated."
        redirect_to admin_collection_path(collection)
      end
    end

    private

    def sanitized_params
      params.require(:collection).permit(:id, :contentdm_alias,
                                         :medusa_cfs_directory_id,
                                         :medusa_file_group_id,
                                         :metadata_profile_id,
                                         :package_profile_id,
                                         :published_in_dls,
                                         :rightsstatements_org_uri)
    end

    def update_collections_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_COLLECTION)
    end

  end

end
