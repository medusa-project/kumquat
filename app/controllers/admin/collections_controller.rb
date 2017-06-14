module Admin

  class CollectionsController < ControlPanelController

    before_action :modify_collections_rbac, only: [:edit, :update, :sync]

    ##
    # Responds to GET /admin/collections/:id/edit
    #
    def edit
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile_options_for_select = MetadataProfile.all.order(:name).
          map{ |t| [ t.name, t.id ] }
      @package_profile_options_for_select = PackageProfile.all.
          map{ |t| [ t.name, t.id ] }
    end

    ##
    # Responds to GET /admin/collections
    #
    def index
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @start = params[:start] ? params[:start].to_i : 0

      @collections = Collection.solr.order(Collection::SolrFields::TITLE).
          start(@start).limit(@limit)
      # Will be true when searching/filtering.
      if params[:published].present?
        @collections = @collections.
            where("(*#{params[:q].gsub(' ', '*')}*)").
            filter(Collection::SolrFields::PUBLISHED =>
                       params[:published].to_s == '1' ? true : false).
            filter(Collection::SolrFields::PUBLISHED_IN_DLS =>
                       params[:published_in_dls].to_s == '1' ? true : false)
      end
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          download = Download.create
          DownloadAllTsvJob.perform_later(download)
          redirect_to download_url(download)
        end
      end
    end

    ##
    # Responds to GET /admin/collections/:id
    #
    def show
      @collection = Collection.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @collection

      @file_group = @collection.medusa_file_group_id.present? ?
          @collection.medusa_file_group : nil
      @can_reindex = (@collection.published_in_dls and
          @collection.medusa_file_group)
    end

    ##
    # Responds to GET /admin/collections/:id/statistics
    #
    def statistics
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      # Items section
      @num_objects = @collection.num_objects
      @num_items = @collection.num_items

      # Binaries section
      sql = "SELECT COUNT(binaries.id) AS count
      FROM binaries
      LEFT JOIN items ON binaries.item_id = items.id
      LEFT JOIN collections ON items.collection_repository_id = collections.repository_id
      WHERE collections.repository_id = '#{@collection.repository_id}'"
      result = ActiveRecord::Base.connection.execute(sql)
      @num_binaries = result[0]['count'].to_i

      sql = "SELECT regexp_matches(lower(repository_relative_pathname),'\\.(\\w+)$') AS extension,
        COUNT(binaries.id) AS count
      FROM binaries
      LEFT JOIN items ON binaries.item_id = items.id
      LEFT JOIN collections ON items.collection_repository_id = collections.repository_id
      WHERE collections.repository_id = '#{@collection.repository_id}'
        AND repository_relative_pathname ~ '\\.'
      GROUP BY extension
      ORDER BY extension ASC"
      @extension_counts = ActiveRecord::Base.connection.execute(sql)

      # Metadata section
      sql = "SELECT COUNT(entity_elements.id) AS count
      FROM entity_elements
      LEFT JOIN items ON entity_elements.item_id = items.id
      LEFT JOIN collections ON items.collection_repository_id = collections.repository_id
      WHERE collections.repository_id = '#{@collection.repository_id}'"
      result = ActiveRecord::Base.connection.execute(sql)
      @num_ascribed_elements = result[0]['count'].to_i +
          @collection.elements.count
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

    ##
    # Responds to POST /admin/collections/:id
    #
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
        # This will also cause items to be reindexed. If the collection's
        # "published" status was changed, it will propagate to items once the
        # job is done and commits Solr.
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
                                         :harvestable,
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
