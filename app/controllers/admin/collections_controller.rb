module Admin

  class CollectionsController < ControlPanelController

    before_action :modify_collections_rbac, only: [:edit, :update, :sync]

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
      # Will be true when searching/filtering.
      if params[:published].present?
        where = "(*#{params[:q].gsub(' ', '*')}*)"
        @collections.where("#{Collection::SolrFields::TITLE}:#{where}").
            where(Collection::SolrFields::PUBLISHED => params[:published] == '1' ? true : false).
            where(Collection::SolrFields::PUBLISHED_IN_DLS => params[:published_in_dls] == '1' ? true : false)
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

        ActiveRecord::Base.transaction do # trigger after_commit callbacks
          collection.update!(sanitized_params)
        end
        Solr.instance.commit

        # We will also need to update the effective allowed/denied roles
        # of each item in the collection, which will take some time, so we
        # will do it in the background.
        PropagateRolesToItemsJob.perform_later(collection.repository_id)
      rescue => e
        handle_error(e)
        redirect_to edit_admin_collection_path(collection)
      else
        flash['success'] = "Collection \"#{collection.title}\" updated."
        redirect_to admin_collection_path(collection)
      end
    end

    private

    def modify_collections_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::Permissions::MODIFY_COLLECTIONS)
    end

    def sanitized_params
      params.require(:collection).permit(:id, :contentdm_alias,
                                         :medusa_cfs_directory_id,
                                         :medusa_file_group_id,
                                         :metadata_profile_id,
                                         :package_profile_id,
                                         :published_in_dls,
                                         :rightsstatements_org_uri,
                                         allowed_role_ids: [],
                                         denied_role_ids: [])
    end

  end

end
