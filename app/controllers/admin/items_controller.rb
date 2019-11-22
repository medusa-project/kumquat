module Admin

  class ItemsController < ControlPanelController

    PERMITTED_PARAMS = [:id, :contentdm_alias, :contentdm_pointer, :df,
                        :embed_tag, :'fq[]', :item_set, :page_number,
                        :published, :q, :representative_item_id,
                        :subpage_number, :variant, allowed_host_group_ids: [],
                        denied_host_group_ids: []]

    before_action :purge_items_rbac, only: :destroy_all
    before_action :modify_items_rbac, only: [:batch_change_metadata,
                                             :destroy_all, :edit, :import,
                                             :migrate_metadata,
                                             :replace_metadata, :sync, :update]
    before_action :set_permitted_params, only: [:index, :show]

    ##
    # Adds the items with the given IDs to the given item set.
    #
    # Responds to POST /admin/collections/:collection_id/items/add-items-to-item-set
    #
    def add_items_to_item_set
      item_ids = params[:items]
      if item_ids&.any?
        item_set = ItemSet.find(params[:item_set])
        item_ids.each do |item_id|
          item = Item.find_by_repository_id(item_id)
          item_set.add_item_and_children(item) if item
        end
        flash['success'] = "Added #{item_ids.length} item(s) to #{item_set}."
      end
      redirect_back fallback_location: admin_collection_items_path(params[:collection_id])
    end

    ##
    # Adds the results from the given query to the given item set.
    #
    # Query syntax is the same as for item results view.
    #
    # Responds to POST /admin/collections/:collection_id/items/add-query-to-item-set
    #
    def add_query_to_item_set
      collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless collection

      item_set = ItemSet.find(params[:item_set])
      finder   = querying_item_finder_for(collection)
      results  = finder.to_a
      count    = finder.count
      begin
        results.each do |item|
          item_set.add_item(item)
        end
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Added #{count} items to #{item_set}."
      ensure
        redirect_back fallback_location: admin_collection_items_path(collection)
      end
    end

    ##
    # Batch-changes metadata elements.
    #
    # Responds to POST /admin/collections/:collection_id/items/batch-change-metadata
    #
    def batch_change_metadata
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        finder = editing_item_finder_for(col)
        BatchChangeItemMetadataJob.perform_later(finder.to_a.select{ |e| e },
                                                 params[:element].to_s,
                                                 params[:replace_values].map(&:to_unsafe_hash))
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Batch-changing metadata values in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(col)
      end
    end

    ##
    # Responds to DELETE /admin/collections/:collection_id/items
    #
    def destroy_all
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        PurgeItemsJob.perform_later(col.repository_id)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Purging items in the background. '\
            'This should take less than a minute.'
      ensure
        redirect_to admin_collection_items_url(col)
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/:id
    #
    def edit
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item

      @variants = Item::Variants.constants.map do |v|
        value = Item::Variants::const_get(v)
        [value, value]
      end
      @variants.sort!
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/edit
    #
    def edit_all
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile = @collection.effective_metadata_profile
      @item_set = nil
      @start = params[:start].to_i
      @limit = 20

      # If there is an ItemSet ID in the URL, we want to edit all of its items.
      # Otherwise, we want to edit items from the collection item results.
      # In both cases, results must include children.
      if params[:item_set]
        @item_set = ItemSet.find(params[:item_set])
        finder = ItemFinder.new.
            filter(Item::IndexFields::REPOSITORY_ID,
                   @item_set.items.pluck(:repository_id))
      else
        finder = ItemFinder.new.
            collection(@collection).
            query(params[:df], params[:q]).
            facet_filters(params[:fq])
      end

      finder = finder.
          aggregations(false).
          include_unpublished(true).
          include_children_in_results(true).
          order(Item::IndexFields::STRUCTURAL_SORT).
          start(@start).
          limit(@limit)

      @items = finder.to_a
      @current_page = finder.page
      @count = finder.count

      respond_to do |format|
        format.html
        format.js
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items
    #
    def index
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)

      finder = querying_item_finder_for(@collection, @start, @limit)
      @items = finder.to_a
      @facets = finder.facets

      @current_page = finder.page
      @count = finder.count
      @num_results_shown = [@limit, @count].min
      @metadata_profile = @collection.effective_metadata_profile

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          only_undescribed = (params[:only_undescribed] == 'true')
          # TSV generation is roughly O(n) with number of items. If there are
          # more than n items in the collection, do the download asynchronously.
          if @collection.items.count > 2000
            download = Download.create(ip_address: request.remote_ip)
            DownloadTsvJob.perform_later(@collection, download,
                                         only_undescribed)
            redirect_to download_url(download)
          else
            headers['Content-Disposition'] = 'attachment; filename="items.tsv"'
            headers['Content-Type'] = 'text/tab-separated-values'
            exporter = ItemTsvExporter.new
            render plain: exporter.items_in_collection(@collection,
                                                       only_undescribed: only_undescribed)
          end
        end
      end
    end

    ##
    # Imports item metadata from TSV.
    #
    # Responds to POST /admin/collections/:collection_id/items/import
    #
    def import
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col

      respond_to do |format|
        format.tsv do
          # Can't pass an uploaded file to an ActiveJob, so it will be saved
          # to this temp file, whose pathname gets passed to the job.
          tempfile = Tempfile.new('uploaded-items.tsv')
          # The finalizer would otherwise delete it.
          ObjectSpace.undefine_finalizer(tempfile)

          begin
            raise 'No TSV content specified.' if params[:tsv].blank?
            tsv = params[:tsv].read.force_encoding('UTF-8')
            tempfile.write(tsv)
            tempfile.close
            UpdateItemsFromTsvJob.perform_later(tempfile.path,
                                                params[:tsv].original_filename)
          rescue => e
            tempfile.unlink
            handle_error(e)
            redirect_back fallback_location: admin_collection_items_url(col)
          else
            flash['success'] = 'Updating items in the background. This '\
            'may take a while.'
            redirect_back fallback_location: admin_collection_items_url(col)
          end
        end
      end
    end

    ##
    # Migrates values from elements of one name to elements of a different
    # name.
    #
    # Responds to POST /admin/collections/:collection_id/items/migrate-metadata
    #
    def migrate_metadata
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        finder = editing_item_finder_for(col)
        MigrateItemMetadataJob.perform_later(finder.to_a.select{ |e| e },
                                             params[:source_element],
                                             params[:dest_element])
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Migrating metadata elements in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(col)
      end
    end

    ##
    # Responds to PATCH /admin/:collections/:collection_id/items/publish
    #
    def publish
      publish_or_unpublish(true)
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/:item_id/purge-cached-images
    #
    def purge_cached_images
      item = Item.find_by_repository_id(params[:item_id])
      raise ActiveRecord::RecordNotFound unless item
      begin
        ImageServer.instance.purge_item_images_from_cache(item)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'All images relating to this item have been purged '\
        'from the image server cache. You may need to clear your browser '\
        'cache to see any changes take effect.'
      ensure
        redirect_back fallback_location: admin_collection_item_path(item.collection, item)
      end
    end

    ##
    # Finds and replaces values across metadata elements.
    #
    # Responds to POST /admin/collections/:collection_id/items/replace-metadata
    #
    def replace_metadata
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        finder = editing_item_finder_for(col)
        ReplaceItemMetadataJob.perform_later(finder.to_a.select{ |e| e },
                                             params[:matching_mode],
                                             params[:find_value],
                                             params[:element],
                                             params[:replace_mode],
                                             params[:replace_value])
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Replacing metadata values in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(col)
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/:id
    #
    def show
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item

      @pages = @item.parent ? @item.parent.items : @item.items
    end

    ##
    # Syncs items from Medusa.
    #
    # N.B. After being available for some time, the end-user terminology for
    # this feature was changed to "import" as part of a broader Medusa-wide
    # terminology change (DLD-112). I decided to keep referring to it
    # internally as "syncing" because that is a better description of what's
    # happening. -- alexd@illinois.edu
    #
    # Responds to POST /admin/collections/:collection_id/items/sync
    #
    def sync
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col

      begin
        params[:options] = {} unless params[:options].kind_of?(Hash)
        SyncItemsJob.perform_later(params[:collection_id],
                                   params[:ingest_mode],
                                   params[:options].to_unsafe_hash)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Importing items in the background. This '\
        'may take a while.'
      ensure
        redirect_to admin_collection_items_url(col)
      end
    end

    ##
    # Responds to PATCH /admin/:collections/:collection_id/items/unpublish
    #
    def unpublish
      publish_or_unpublish(false)
    end

    def update
      item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless item

      begin
        # If we are updating metadata, we will need to process the elements
        # manually.
        if params[:elements].respond_to?(:each)
          ActiveRecord::Base.transaction do
            item.elements.destroy_all
            params[:elements].each do |name, vocabs|
              vocabs.each do |vocab_id, occurrences|
                occurrences.each do |occurrence|
                  if occurrence[:string].present? or occurrence[:uri].present?
                    item.elements.build(name: name,
                                        value: occurrence[:string],
                                        uri: occurrence[:uri],
                                        vocabulary_id: vocab_id)
                  end
                end
              end
            end
            item.save!
          end
        end

        if params[:item]
          ActiveRecord::Base.transaction do # trigger after_commit callbacks
            item.update!(sanitized_params)
          end

          # We will also need to propagate various item properties (published
          # status, allowed/denied host groups, etc.) to its child items. This
          # will take some time, so we'll do it in the background.
          PropagatePropertiesToChildrenJob.perform_later(item.repository_id)
        end
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Item \"#{item.title}\" updated."
      ensure
        redirect_to edit_admin_collection_item_path(item.collection, item)
      end
    end

    ##
    # Responds to POST /admin/items/update
    #
    def update_all
      num_updated = 0
      ActiveRecord::Base.transaction do
        params[:items].each do |id, element_params|
          item = Item.find_by_repository_id(id)
          if item
            item.elements.destroy_all
            # Entry values (textarea contents) use the same syntax as TSV.
            element_params.each do |name, entry_value|
              case name
                when 'variant'
                  item.variant = Item::Variants::all.include?(entry_value) ?
                      entry_value : nil
                when 'page'
                  item.page_number = entry_value.length > 0 ?
                      entry_value.to_i : nil
                when 'subpage'
                  item.subpage_number = entry_value.length > 0 ?
                      entry_value.to_i : nil
                else
                  item.elements += ItemElement.elements_from_tsv_string(name,
                                                                        entry_value)
              end
            end
            item.save!
            num_updated += 1
          end
        end
      end

      flash['success'] = "#{num_updated} items updated."
      redirect_back fallback_location: admin_collections_path
    end

    private

    def editing_item_finder_for(collection)
      ItemFinder.new.
          collection(collection).
          query(params[:df], params[:q]).
          search_children(false).
          include_unpublished(true).
          include_children_in_results(!collection.free_form?).
          facet_filters(params[:fq]).
          aggregations(false)
    end

    def querying_item_finder_for(collection, start = 0,
                                 limit = ElasticsearchClient::MAX_RESULT_WINDOW)
      ItemFinder.new.
          collection(collection).
          query(params[:df], params[:q]).
          search_children(false).
          include_unpublished(true).
          exclude_variants(*Item::Variants::non_filesystem_variants).
          facet_filters(params[:fq]).
          order(params[:sort]).
          start(start).
          limit(limit)
    end

    def modify_items_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::Permissions::MODIFY_ITEMS)
    end

    ##
    # @param publish [Boolean]
    #
    def publish_or_unpublish(publish)
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        # If we are (un)publishing only checked items, params[:id] will be set.
        if params[:id].respond_to?(:any?) and params[:id].any?
          ids = params[:id]
        else
          finder = editing_item_finder_for(col)
          items  = finder.to_a.select{ |i| i }
          ids    = items.map(&:repository_id)
        end
        Item.where('repository_id IN (?)', ids)
            .update_all(published: publish)
      rescue => e
        handle_error(e)
      else
        flash['success'] = "#{publish ? 'P' : 'Unp'}ublished #{ids.length} items."
      ensure
        redirect_back fallback_location: admin_collection_items_path(col)
      end
    end

    def purge_items_rbac
      redirect_to(admin_collection_url(params[:collection_id])) unless
          current_user.can?(Permission::Permissions::PURGE_ITEMS_FROM_COLLECTION)
    end

    def sanitized_params
      # Metadata elements are not included here, as they are processed
      # separately.
      params.require(:item).permit(PERMITTED_PARAMS)
    end

    def set_permitted_params
      @permitted_params = params.permit(PERMITTED_PARAMS)
    end

  end

end
