module Admin

  class CollectionsController < ControlPanelController

    PERMITTED_PARAMS = [:q, :public_in_medusa, :published_in_dls, :start]

    before_action :authorize_modify_collections, only: [:edit, :update, :sync]

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

      profile = @collection.metadata_profile || MetadataProfile.default
      @descriptive_element_options_for_select =
          profile.elements.map{ |e| [e.label, e.id] }
    end

    ##
    # Responds to GET /admin/collections
    #
    def index
      @limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
      @start = params[:start] ? params[:start].to_i : 0

      relation = Collection.search.
          aggregations(false).
          query_all(params[:q]).
          include_unpublished(true).
          include_restricted(true).
          order(CollectionElement.new(name: 'title').indexed_sort_field).
          start(@start).
          limit(@limit)

      if params[:public_in_medusa] == '1'
        relation = relation.filter(Collection::IndexFields::PUBLIC_IN_MEDUSA, true)
      end
      if params[:published_in_dls] == '1'
        relation = relation.filter(Collection::IndexFields::PUBLISHED_IN_DLS, true)
      end

      @collections = relation.to_a
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
      @count = relation.count

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          download = Download.create(ip_address: request.remote_ip)
          DownloadAllTsvJob.perform_later(download)
          redirect_to download_url(download)
        end
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/purge-cached-images
    #
    def purge_cached_images
      collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless collection

      PurgeCollectionItemsFromImageServerCacheJob.
          perform_later(collection.repository_id)

      flash['success'] = 'Purging images in the background. (This may take a
          minute.) When complete, you may need to clear your browser cache to
          see any changes take effect.'
      redirect_back fallback_location: admin_collection_path(collection)
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

      sql = "SELECT regexp_matches(lower(object_key),'\\.(\\w+)$') AS extension,
        COUNT(binaries.id) AS count
      FROM binaries
      LEFT JOIN items ON binaries.item_id = items.id
      LEFT JOIN collections ON items.collection_repository_id = collections.repository_id
      WHERE collections.repository_id = '#{@collection.repository_id}'
        AND object_key ~ '\\.'
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
    # Sync collections from Medusa.
    #
    # N.B.: The end-user terminology for this feature was changed to "index" as
    # part of a broader Medusa-wide terminology change (DLD-112). I decided to
    # keep referring to it internally as "syncing" because that is a better
    # description of what's happening, and also because "index" has a
    # particular meaning that is already being used to describe indexing in
    # Elasticsearch. -- @adolski
    #
    # Responds to PATCH /admin/collections/sync
    #
    def sync
      SyncCollectionsJob.perform_later
      flash['success'] = 'Indexing collections in the background.
        (This will take a minute.)'
      redirect_back fallback_location: admin_collections_path
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

        # We will also need to propagate various collection properties
        # (published status, allowed/denied host groups, etc.) to the items
        # contained within the collection. This will take some time, so we'll
        # do it in the background.
        PropagatePropertiesToItemsJob.perform_later(collection.repository_id)
      rescue => e
        handle_error(e)
        redirect_to edit_admin_collection_path(collection)
      else
        flash['success'] = "Collection \"#{collection.title}\" updated."
        redirect_to admin_collection_path(collection)
      end
    end

    private

    def authorize_modify_collections
      unless current_user.can?(Permissions::MODIFY_COLLECTIONS)
        flash['error'] = 'You do not have permission to perform this action.'
        redirect_to admin_collections_url
      end
    end

    def sanitized_params
      params.require(:collection).permit(:id, :contentdm_alias,
                                         :descriptive_element_id,
                                         :harvestable, :harvestable_by_idhh,
                                         :harvestable_by_primo,
                                         :medusa_directory_uuid,
                                         :medusa_file_group_id,
                                         :metadata_profile_id,
                                         :package_profile_id,
                                         :published_in_dls,
                                         :restricted,
                                         :rightsstatements_org_uri,
                                         allowed_host_group_ids: [],
                                         denied_host_group_ids: [])
    end

  end

end
