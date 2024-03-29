# frozen_string_literal: true

module Admin

  class ItemsController < ControlPanelController

    PERMITTED_SEARCH_PARAMS = [:df, :fq, :q, :sort, :start]

    before_action :set_collection, only: [:add_query_to_item_set,
                                          :batch_change_metadata, :edit_all,
                                          :enable_full_text_search,
                                          :disable_full_text_search,
                                          :import,
                                          :import_embedded_file_metadata,
                                          :index, :migrate_metadata, :publish,
                                          :replace_metadata, :sync, :unpublish]
    before_action :set_item, except: [:add_items_to_item_set,
                                      :add_query_to_item_set,
                                      :batch_change_metadata,
                                      :disable_full_text_search,
                                      :edit_all, :enable_full_text_search,
                                      :import, :import_embedded_file_metadata,
                                      :index, :migrate_metadata, :publish,
                                      :replace_metadata, :run_ocr, :sync,
                                      :unpublish, :update_all]
    before_action :authorize_item, except: [:add_items_to_item_set,
                                            :add_query_to_item_set,
                                            :batch_change_metadata,
                                            :disable_full_text_search,
                                            :edit_all,
                                            :enable_full_text_search, :import,
                                            :import_embedded_file_metadata,
                                            :index, :migrate_metadata,
                                            :publish, :replace_metadata,
                                            :run_ocr, :sync, :unpublish,
                                            :update_all]

    ##
    # Adds the items with the given IDs to the given item set.
    #
    # Responds to
    # `POST /admin/collections/:collection_id/items/add-items-to-item-set`
    #
    def add_items_to_item_set
      authorize(Item)
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
    # Responds to `POST /admin/collections/:collection_id/items/add-query-to-item-set`
    #
    def add_query_to_item_set
      authorize(Item)
      item_set = ItemSet.find(params[:item_set]) # TODO: return HTTP 400 instead of 404 if this is missing
      relation = querying_item_relation_for(@collection)
      results  = relation.to_a
      count    = relation.count
      begin
        results.each do |item|
          item_set.add_item(item)
        end
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Added #{count} items to #{item_set}."
      ensure
        redirect_back fallback_location: admin_collection_items_path(@collection)
      end
    end

    ##
    # Changes metadata elements across multiple items.
    #
    # Responds to `POST /admin/collections/:collection_id/items/batch-change-metadata`
    #
    def batch_change_metadata
      authorize(Item)
      begin
        relation = editing_item_relation_for(@collection)
        BatchChangeItemMetadataJob.perform_later(
          item_ids:           relation.to_id_a,
          element_name:       params[:element].to_s,
          replacement_values: params[:replace_values].map(&:to_unsafe_hash),
          user:               current_user)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Batch-changing metadata values in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(@collection)
      end
    end

    ##
    # Responds to `PATCH /admin/collections/:collection_id/items/disable-full-text-search`
    #
    def disable_full_text_search
      authorize(Item)
      enable_or_disable_full_text_search(false)
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/items/:id/edit-access`
    # (XHR only)
    #
    def edit_access
      render partial: 'admin/items/access_form'
    end

    ##
    # Renders the metadata table editor.
    #
    # Responds to `GET /admin/collections/:collection_id/items/edit`
    #
    def edit_all
      authorize(Item)
      @metadata_profile = @collection.effective_metadata_profile
      @item_set         = nil
      @start            = params[:start].to_i
      @limit            = 20

      # If there is an ItemSet ID in the URL, we want to edit all of its items.
      # Otherwise, we want to edit items from the collection item results.
      # In both cases, results must include children.
      if params[:item_set]
        @item_set = ItemSet.find(params[:item_set])
        relation = Item.search.filter(Item::IndexFields::REPOSITORY_ID,
                                      @item_set.items.pluck(:repository_id))
      else
        relation = Item.search.
          collection(@collection).
          query(params[:df], params[:q]).
          facet_filters(params[:fq])
      end

      relation.
        aggregations(false).
        include_unpublished(true).
        include_publicly_inaccessible(true).
        include_restricted(true).
        include_children_in_results(true).
        order(Item::IndexFields::STRUCTURAL_SORT).
        start(@start).
        limit(@limit)

      @items        = relation.to_a
      @current_page = relation.page
      @count        = relation.count

      respond_to do |format|
        format.html
        format.js
      end
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/items/:id/edit-info`
    # (XHR only)
    #
    def edit_info
      @variants = Item::Variants.constants.map do |v|
        value = Item::Variants::const_get(v)
        [value, value]
      end
      @variants.sort!
      render partial: 'admin/items/info_form'
    end

    ##
    # Responds to
    # `GET /admin/collections/:collection_id/items/:id/edit-metadata` (XHR only)
    #
    def edit_metadata
      render partial: 'admin/items/metadata_form'
    end

    ##
    # Responds to
    # `GET /admin/collections/:collection_id/items/:id/edit-representation`
    # (XHR only).
    #
    def edit_representation
      # The form is the same for items & collections, except for a different
      # form target.
      render partial: 'admin/collections/representation_form', locals: {
        target: [:admin, @item.collection, @item]
      }
    end

    ##
    # Responds to `PATCH /admin/collections/:collection_id/items/enable-full-text-search`
    #
    def enable_full_text_search
      authorize(Item)
      enable_or_disable_full_text_search(true)
    end

    ##
    # Imports item metadata from TSV.
    #
    # Responds to `POST /admin/collections/:collection_id/items/import`
    #
    def import
      authorize(Item)
      respond_to do |format|
        format.tsv do
          # Can't pass an uploaded file to an ActiveJob, so it will be saved
          # to this temporary file, whose pathname gets passed to the job.
          tempfile = File.join(Dir.tmpdir,
                               "uploaded-items-#{Time.now.strftime("%Y%m%d-%H%m%s")}.tsv")
          begin
            raise 'No TSV content specified.' if params[:tsv].blank?
            tsv = params[:tsv].read.force_encoding('UTF-8')
            File.open(tempfile, "wb") do |file|
              file.write(tsv)
            end
            ItemUpdater.new.validate_tsv(pathname:         tempfile,
                                         metadata_profile: @collection.effective_metadata_profile)
            UpdateItemsFromTsvJob.perform_later(
              tsv_pathname:          tempfile,
              tsv_original_filename: params[:tsv].original_filename,
              user:                  current_user)
          rescue => e
            File.delete(tempfile) if File.exist?(tempfile)
            handle_error(e)
            redirect_back fallback_location: admin_collection_items_url(@collection)
          else
            flash['success'] = 'Updating items in the background. This '\
              'may take a while.'
            redirect_back fallback_location: admin_collection_items_url(@collection)
          end
        end
      end
    end

    ##
    # Imports metadata an item's binaries' embedded metadata.
    #
    # Responds to `POST /admin/collections/:collection_id/items/import-embedded-file-metadata`
    #
    def import_embedded_file_metadata
      authorize(Item)
      begin
        params[:options] = {} unless params[:options].kind_of?(Hash)
        UpdateItemsFromEmbeddedMetadataJob.perform_later(
          collection:           @collection,
          include_date_created: StringUtils.to_b(params[:include_date_created]),
          user:                 current_user)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Importing item metadata in the background. This '\
          'may take a while.'
      ensure
        redirect_to admin_collection_items_url(@collection)
      end
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/items`
    #
    def index
      authorize(Item)
      @start             = params[:start] ? params[:start].to_i : 0
      @limit             = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
      relation           = querying_item_relation_for(@collection, @start, @limit)
      @items             = relation.to_a
      @facets            = relation.facets
      @current_page      = relation.page
      @count             = relation.count
      @num_results_shown = [@limit, @count].min
      @metadata_profile  = @collection.effective_metadata_profile

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          only_undescribed = (params[:only_undescribed] == 'true')
          # TSV generation is roughly O(n) with number of items. If there are
          # more than n items in the collection, do the download asynchronously.
          if @collection.items.count > 2000
            download = Download.create(ip_address: request.remote_ip)
            DownloadItemsTsvJob.perform_later(collection:       @collection,
                                              download:         download,
                                              only_undescribed: only_undescribed,
                                              user:             current_user)
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
    # Migrates values from elements of one name to elements of a different
    # name.
    #
    # Responds to `POST /admin/collections/:collection_id/items/migrate-metadata`
    #
    def migrate_metadata
      authorize(Item)
      begin
        relation = editing_item_relation_for(@collection)
        MigrateItemMetadataJob.perform_later(item_ids:       relation.to_id_a,
                                             source_element: params[:source_element],
                                             dest_element:   params[:dest_element],
                                             user:           current_user)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Migrating metadata elements in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(@collection)
      end
    end

    ##
    # Responds to `POST /admin/collections/:collection_id/items/:item_id/publicize-child-binaries`
    #
    def publicize_child_binaries
      @item.all_children.each do |child|
        child.binaries.update_all(public: true)
      end
    rescue => e
      handle_error(e)
    else
      flash['success'] = 'All binaries attached to all child items have been publicized.'
    ensure
      redirect_back fallback_location: admin_collection_item_path(@item.collection, @item)
    end

    ##
    # Responds to `PATCH /admin/collections/:collection_id/items/publish`
    #
    def publish
      authorize(Item)
      publish_or_unpublish(true)
    end

    ##
    # Responds to
    # `POST /admin/collections/:collection_id/items/:item_id/purge-cached-images`
    #
    def purge_cached_images
      ImageServer.instance.purge_item_images_from_cache(@item)
    rescue => e
      handle_error(e)
    else
      flash['success'] = 'All images relating to this item have been purged '\
      'from the image server cache. You may need to clear your browser '\
      'cache to see any changes take effect.'
    ensure
      redirect_back fallback_location:
                      admin_collection_item_path(@item.collection, @item)
    end

    ##
    # Finds and replaces values across metadata elements.
    #
    # Responds to `POST /admin/collections/:collection_id/items/replace-metadata`
    #
    def replace_metadata
      authorize(Item)
      begin
        relation = editing_item_relation_for(@collection)
        ReplaceItemMetadataJob.perform_later(item_ids:      relation.to_id_a,
                                             matching_mode: params[:matching_mode],
                                             find_value:    params[:find_value],
                                             element_name:  params[:element],
                                             replace_mode:  params[:replace_mode],
                                             replace_value: params[:replace_value],
                                             user:          current_user)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Replacing metadata values in the background. '\
        'This should take less than a minute.'
      ensure
        redirect_back fallback_location: admin_collection_items_path(@collection)
      end
    end

    ##
    # Runs OCR on all relevant binaries of an item and all of its children,
    # in the background.
    #
    # Responds to:
    #
    # * `PATCH /admin/collections/:collection_id/items/:item_id/run-ocr` (for
    #   OCRing a single item)
    # * `PATCH /admin/collections/:collection_id/items/run-ocr` (for OCRing a
    #   whole collection, or selected items in a collection)
    #
    def run_ocr # TODO: split this into 2 methods
      authorize(Item)
      flash_msg = 'Running OCR in the background. This may take a while.'
      if params[:item_id] # single item
        begin
          item = Item.find_by_repository_id(params[:item_id])
          raise ActiveRecord::RecordNotFound unless item

          OcrItemJob.perform_later(item:                  item,
                                   language_code:         params[:language],
                                   include_already_ocred: params[:include_ocred],
                                   user:                  current_user)
        rescue => e
          handle_error(e)
        else
          flash['success'] = flash_msg
        ensure
          redirect_back fallback_location:
                          admin_collection_item_path(item.collection, item)
        end
      else # multiple items or a whole collection
        begin
          collection = Collection.find_by_repository_id(params[:collection_id])
          raise ActiveRecord::RecordNotFound unless collection

          if params[:target] == 'checked'
            OcrItemsJob.perform_later(item_ids:              params[:items],
                                      language_code:         params[:language],
                                      include_already_ocred: params[:include_ocred],
                                      user:                  current_user)
          else
            OcrCollectionJob.perform_later(collection:            collection,
                                           language_code:         params[:language],
                                           include_already_ocred: params[:include_ocred],
                                           user:                  current_user)
          end
        rescue => e
          handle_error(e)
        else
          flash['success'] = flash_msg
        ensure
          redirect_back fallback_location:
                          admin_collection_items_path(collection)
        end
      end
    end

    ##
    # Responds to `GET /admin/collections/:collection_id/items/:id`
    #
    def show
      @pages = @item.parent ? @item.parent.items : @item.items
      @current_opensearch_document =
        JSON.pretty_generate(@item.indexed_document)
      @expected_opensearch_document =
        JSON.pretty_generate(@item.as_indexed_json)
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
    # Responds to `POST /admin/collections/:collection_id/items/sync`
    #
    def sync
      authorize(Item)
      begin
        SyncItemsJob.perform_later(collection:  @collection,
                                   ingest_mode: params[:ingest_mode],
                                   user:        current_user)
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Importing items in the background. This '\
        'may take a while.'
      ensure
        redirect_to admin_collection_items_url(@collection)
      end
    end

    ##
    # Responds to
    # `POST /admin/collections/:collection_id/items/:item_id/unpublicize-child-binaries`
    #
    def unpublicize_child_binaries
      @item.all_children.each do |child|
        child.binaries.update_all(public: false)
      end
    rescue => e
      handle_error(e)
    else
      flash['success'] = 'All binaries attached to all child items have been unpublicized.'
    ensure
      redirect_back fallback_location: admin_collection_item_path(@item.collection, @item)
    end

    ##
    # Responds to `PATCH /admin/collections/:collection_id/items/unpublish`
    #
    def unpublish
      authorize(Item)
      publish_or_unpublish(false)
    end

    def update
      # If we are updating metadata, we will need to process the elements
      # manually.
      if params[:elements].respond_to?(:each)
        ActiveRecord::Base.transaction do
          @item.elements.destroy_all
          params[:elements].each do |name, vocabs|
            vocabs.each do |vocab_id, occurrences|
              occurrences.each do |occurrence|
                if occurrence[:string].present? || occurrence[:uri].present?
                  @item.elements.build(name:          name,
                                       value:         occurrence[:string],
                                       uri:           occurrence[:uri],
                                       vocabulary_id: vocab_id)
                end
              end
            end
          end
          @item.save!
        end
      end

      if params[:item]
        ActiveRecord::Base.transaction do # trigger after_commit callbacks
          # Process the image uploaded from the representative image form
          image = params[:item][:representative_image_data]
          if image
            @item.upload_representative_image(io:       image.read,
                                              filename: image.original_filename)
            # Also activate it for convenience's sake (DLD-408)
            @item.representation_type = Representation::Type::LOCAL_FILE
          end
          @item.update!(permitted_params)

          # We will also need to propagate various item properties (published
          # status, allowed host groups, etc.) to its child items. This will
          # take some time, so we'll do it in the background.
          PropagatePropertiesToChildrenJob.perform_later(item: @item,
                                                         user: current_user)
        end
      end
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Item \"#{@item.title}\" updated."
    ensure
      redirect_to admin_collection_item_path(@item.collection, @item)
    end

    ##
    # Responds to `POST /admin/items/update`
    #
    def update_all
      authorize(Item)
      num_updated = 0
      ActiveRecord::Base.transaction do
        params[:items]&.each do |id, element_params|
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

    def authorize_item
      @item ? authorize(@item) : skip_authorization
    end

    def editing_item_relation_for(collection)
      Item.search.
          collection(collection).
          query(params[:df], params[:q]).
          search_children(false).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
          include_children_in_results(!collection.free_form?).
          facet_filters(params[:fq]).
          aggregations(false)
    end

    def querying_item_relation_for(collection,
                                   start = 0,
                                   limit = OpensearchClient::MAX_RESULT_WINDOW)
      Item.search.
          collection(collection).
          query(params[:df], params[:q]).
          search_children(false).
          include_unpublished(true).
          include_publicly_inaccessible(true).
          include_restricted(true).
          exclude_variants(*Item::Variants::non_filesystem_variants).
          facet_filters(params[:fq]).
          order(params[:sort]).
          start(start).
          limit(limit)
    end

    ##
    # @param enable [Boolean]
    #
    def enable_or_disable_full_text_search(enable)
      # If we are (un)publishing only checked items, params[:id] will be set.
      if params[:id].respond_to?(:any?) && params[:id].any?
        ids = params[:id]
      else
        relation = editing_item_relation_for(@collection)
        relation.include_children_in_results(true)
        items    = relation.to_a.select(&:present?)
        ids      = items.map(&:repository_id)
      end
      Item.where('repository_id IN (?)', ids)
          .update_all(expose_full_text_search: enable)
    rescue => e
      handle_error(e)
    else
      flash['success'] = "#{enable ? 'En' : 'Dis'}abled "\
                         "full text search for #{ids.length} items."
    ensure
      redirect_back fallback_location: admin_collection_items_path(@collection)
    end

    ##
    # @param publish [Boolean]
    #
    def publish_or_unpublish(publish)
      # If we are (un)publishing only checked items, params[:id] will be set.
      if params[:id].respond_to?(:any?) && params[:id].any?
        ids = params[:id]
      else
        relation = editing_item_relation_for(@collection)
        relation.include_children_in_results(true)
        items    = relation.to_a.select(&:present?)
        ids      = items.map(&:repository_id)
      end
      Item.where('repository_id IN (?)', ids)
          .update_all(published: publish)
    rescue => e
      handle_error(e)
    else
      flash['success'] = "#{publish ? 'P' : 'Unp'}ublished #{ids.length} items."
    ensure
      redirect_back fallback_location: admin_collection_items_path(@collection)
    end

    def permitted_params
      # Metadata elements are not included here, as they are processed
      # separately.
      params.require(:item).permit(:id, :contentdm_alias, :contentdm_pointer,
                                   :embed_tag,  :expose_full_text_search,
                                   :item_set, :page_number, :published,
                                   :representation_type,
                                   :representative_medusa_file_id,
                                   :representative_image,
                                   :representative_item_id,
                                   :subpage_number, :variant,
                                   allowed_host_group_ids: [],
                                   allowed_netids: [:expires, :netid])
    end

    def set_collection
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection
    end

    def set_item
      @item = Item.find_by_repository_id(params[:item_id] || params[:id])
      raise ActiveRecord::RecordNotFound unless @item
    end

  end

end
