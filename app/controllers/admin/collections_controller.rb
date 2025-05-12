# frozen_string_literal: true

module Admin

  class CollectionsController < ControlPanelController

    PERMITTED_SEARCH_PARAMS = [:public_in_medusa, :published_in_dls, :q, :start]

    before_action :set_collection, except: [:index, :items, :sync]
    before_action :authorize_collection, except: [:index, :items, :sync]

    ##
    # Responds to `DELETE /admin/collections/:collection_id/items`
    #
    def delete_items
      PurgeItemsJob.perform_later(collection: @collection,
                                  user:       current_user)
    rescue => e
      handle_error(e)
    else
      flash['success'] = 'Purging items in the background. '\
        'This should take less than a minute.'
    ensure
      redirect_to admin_collection_items_path(@collection)
    end

    ##
    # Responds to `GET /admin/collections/:id/edit-access` (XHR only).
    #
    def edit_access
      render partial: 'admin/collections/access_form'
    end

    ##
    # Responds to `GET /admin/collections/:id/edit-info` (XHR only).
    #
    def edit_info
      @metadata_profile_options_for_select = MetadataProfile.all.order(:name).
          map{ |t| [ t.name, t.id ] }
      @package_profile_options_for_select = PackageProfile.all.
          map{ |t| [ t.name, t.id ] }

      profile = @collection.metadata_profile || MetadataProfile.default
      @descriptive_element_options_for_select =
          profile.elements.map{ |e| [e.label, e.id] }
      render partial: 'admin/collections/info_form'
    end

    ##
    # Renders HTML for the edit-email-watchers modal.
    #
    # Responds to `GET /admin/collections/:collection_id/edit-email-watchers`
    # (XHR only).
    #
    def edit_email_watchers
      render partial: 'admin/collections/email_watchers_form'
    end

    ##
    # Responds to
    # `GET /admin/collections/:collection_id/edit-representation` (XHR only).
    #
    def edit_representation
      render partial: 'admin/collections/representation_form', locals: {
        target: [:admin, @collection]
      }
    end

    ##
    # Responds to `GET /admin/collections`
    #
    def index
      authorize(Collection)
      @limit = request.format == :tsv ?
                 999999 : Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
      @start = params[:start] ? params[:start].to_i : 0

      relation = Collection.search.
          aggregations(false).
          query_all(params[:q]).
          include_unpublished(true).
          include_restricted(true).
          search_children(true).
          order(CollectionElement.new(name: 'title').indexed_sort_field).
          start(@start).
          limit(@limit)

      if params[:public_in_medusa] == '1'
        relation = relation.filter(Collection::IndexFields::PUBLIC_IN_MEDUSA, true)
      end
      if params[:published_in_dls] == '1'
        relation = relation.filter(Collection::IndexFields::PUBLISHED_IN_DLS, true)
      end

      @collections  = relation.to_a
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || @limit == 1
      @count        = relation.count

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          download = Download.create!(ip_address: request.remote_ip)
          DownloadCollectionsTsvJob.perform_later(collection_ids: @collections.map(&:repository_id),
                                                  download:       download,
                                                  user:           current_user)
          redirect_to download_url(download)
        end
      end
    end

    ##
    # Responds to `GET /admin/collections/items`
    #
    def items
      authorize(Collection)
      respond_to do |format|
        format.tsv do
          download = Download.create!(ip_address: request.remote_ip)
          DownloadAllItemsTsvJob.perform_later(download: download,
                                               user:     current_user)
          redirect_to download_url(download)
        end
      end
    end

    ##
    # Responds to `POST /admin/collections/:collection_id/purge-cached-images`
    #
    def purge_cached_images
      PurgeCollectionItemsFromImageServerCacheJob.perform_later(
        collection: @collection,
        user:       current_user)

      flash['success'] = 'Purging images in the background. (This may take a
          minute.) When complete, you may need to clear your browser cache to
          see any changes take effect.'
    ensure
      redirect_back fallback_location: admin_collection_path(@collection)
    end

    ##
    # Responds to `GET /admin/collections/:id`
    #
    def show
      @file_group = @collection.medusa_file_group_uuid.present? ?
          @collection.medusa_file_group : nil
      @can_reindex = (@collection.published_in_dls &&
          @collection.medusa_file_group)
      @current_opensearch_document =
        JSON.pretty_generate(@collection.indexed_document)
      @expected_opensearch_document =
        JSON.pretty_generate(@collection.as_indexed_json)
    end

    ##
    # Responds to `GET /admin/collections/:id/statistics`
    #
    def statistics
      # Items section
      @num_objects = @collection.num_objects
      @num_items   = @collection.num_items

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
    # OpenSearch. -- @adolski
    #
    # Responds to `PATCH /admin/collections/sync`
    #
    def sync
      authorize(Collection)
      SyncCollectionsJob.perform_later(user: current_user)
      flash['success'] = 'Indexing collections in the background.
        (This will take a minute.)'
      redirect_back fallback_location: admin_collections_path
    end

    ##
    # Responds to `PATCH /admin/collections/:id/unwatch`
    #
    def unwatch
      @collection.watches.where(user: current_user).destroy_all
      flash['success'] = "You are no longer watching this collection."
      redirect_back fallback_location: admin_collection_path(@collection)
    end

    ##
    # Responds to `PATCH/POST /admin/collections/:id`
    #
    def update
      if params[:watches] # input from the edit-email-watchers form
        begin
          ActiveRecord::Base.transaction do # trigger after_commit callbacks
            @collection.watches.where('email IS NOT NULL').destroy_all
            params[:watches].select{ |w| w[:email].present? }.each do |watch|
              @collection.watches.build(email: watch[:email])
            end
            @collection.save!
          end
        rescue ActiveRecord::RecordInvalid
          response.headers['X-Kumquat-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @collection }
        else
          flash['success'] = "Watchers updated."
          keep_flash
          redirect_to admin_collection_path(@collection)
        end
      else # all other input
        begin
          ActiveRecord::Base.transaction do # trigger after_commit callbacks
            # Process the image uploaded from the representative image form
            image = params[:collection][:representative_image_data]
            if image
              @collection.upload_representative_image(io:       image.read,
                                                      filename: image.original_filename)
              # Also activate it for convenience's sake (DLD-408)
              @collection.representation_type = Representation::Type::LOCAL_FILE
            end
            @collection.update!(permitted_params)
            # We will also need to propagate various collection properties
            # (published status, allowed host groups, etc.) to the items
            # contained within the collection. This will take some time, so
            # we'll do it in the background.
            PropagatePropertiesToItemsJob.perform_later(collection: @collection,
                                                        user:       current_user)
          end
        rescue => e
          handle_error(e)
          redirect_to admin_collection_path(@collection)
        else
          flash['success'] = "Collection \"#{@collection.title}\" updated."
          redirect_to admin_collection_path(@collection)
        end
      end
    end

    ##
    # Responds to `PATCH /admin/collections/:id/watch`
    #
    def watch
      if @collection.watches.where(user: current_user).count == 0
        @collection.watches.build(user: current_user)
        @collection.save!
      end
      flash['success'] = "You are now watching this collection."
      redirect_back fallback_location: admin_collection_path(@collection)
    end


    private

    def authorize_collection
      @collection ? authorize(@collection) : skip_authorization
    end

    def set_collection
      @collection = Collection.find_by_repository_id(params[:id] || params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

    def permitted_params
      params.require(:collection).permit(:id, :contentdm_alias,
                                         :descriptive_element_id,
                                         :harvestable, :harvestable_by_idhh,
                                         :harvestable_by_primo,
                                         :medusa_directory_uuid,
                                         :medusa_file_group_uuid,
                                         :metadata_profile_id,
                                         :package_profile_id,
                                         :publicize_binaries,
                                         :published_in_dls,
                                         :representation_type,
                                         :representative_item_id,
                                         :representative_medusa_file_id,
                                         :restricted, :rights_term_uri,
                                         :supplementary_document_label,
                                         allowed_host_group_ids: [])
    end

  end

end
