module Admin

  class ItemsController < ControlPanelController

    before_action :modify_items_rbac, only: [:batch_change_metadata, :edit,
                                             :import, :migrate_metadata,
                                             :replace_metadata, :sync, :update]

    ##
    # Batch-changes metadata elements.
    #
    # Responds to POST /admin/collections/:collection_id/items/batch-change-metadata
    #
    def batch_change_metadata
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col
      begin
        BatchChangeItemMetadataJob.perform_later(
            col.repository_id, params[:element], params[:replace_values])
      rescue => e
        handle_error(e)
        redirect_to admin_collection_edit_all_items_url(col)
      else
        flash['success'] = 'Batch-changing metadata values in the background. '\
        'This should take less than a minute.'
        redirect_to admin_collection_edit_all_items_url(col)
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/:id
    #
    def edit
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item

      @variants = Item::Variants.constants.map do |v|
        [v.to_s.downcase.gsub('_', ' ').titleize, v.to_s.downcase.camelize]
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/edit
    #
    def edit_all
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      @metadata_profile = @collection.effective_metadata_profile

      @start = params[:start].to_i
      @limit = 20
      finder = ItemFinder.new.
          collection_id(@collection.repository_id).
          query(params[:q]).
          include_children(true).
          include_unpublished(true).
          filter_queries(params[:fq]).
          start(@start).
          limit(@limit)
      if @collection.package_profile == PackageProfile::FREE_FORM_PROFILE
        finder = finder.
            exclude_variants([Item::Variants::DIRECTORY]).
            sort(Item::SolrFields::GROUPED_SORT => :asc)
      else
        finder = finder.sort(Item::SolrFields::GROUPED_SORT => :asc)
      end

      @items = finder.to_a
      @current_page = finder.page

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
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)

      finder = ItemFinder.new.
          collection_id(@collection.repository_id).
          query(params[:q]).
          include_children(false).
          include_unpublished(true).
          exclude_variants([Item::Variants::FRONT_MATTER, Item::Variants::INDEX,
                            Item::Variants::KEY, Item::Variants::PAGE,
                            Item::Variants::TABLE_OF_CONTENTS,
                            Item::Variants::TITLE]).
          filter_queries(params[:fq]).
          sort(params[:sort]).
          start(@start).
          limit(@limit)
      @items = finder.to_a

      @current_page = finder.page
      @count = finder.count
      @num_results_shown = [@limit, @count].min
      @metadata_profile = finder.effective_metadata_profile

      respond_to do |format|
        format.html
        format.js
        format.tsv do
          headers['Content-Disposition'] = 'attachment; filename="items.tsv"'
          headers['Content-Disposition'] = 'text/tab-separated-values'
          render text: @collection.items_as_tsv(only_undescribed:
                                                    (params[:only_undescribed] == 'true'))
        end
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/import
    #
    def import
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col

      respond_to do |format|
        format.tsv do
          # Can't pass an uploaded file to an ActiveJob, so it will be saved
          # to this temp file, whose pathname gets passed to the job.
          tempfile = Tempfile.new('peartree-uploaded-items.tsv')
          # The finalizer would otherwise delete it.
          ObjectSpace.undefine_finalizer(tempfile)

          begin
            raise 'No TSV content specified.' if params[:tsv].blank?
            tsv = params[:tsv].read.force_encoding('UTF-8')
            tempfile.write(tsv)
            tempfile.close
            ImportItemsFromTsvJob.perform_later(tempfile.path,
                                                params[:tsv].original_filename)
          rescue => e
            tempfile.unlink
            handle_error(e)
            redirect_to admin_collection_items_url(col)
          else
            flash['success'] = 'Importing items in the background. This '\
            'may take a while.'
            redirect_to admin_collection_items_url(col)
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
        MigrateItemMetadataJob.perform_later(
            col.repository_id, params[:source_element], params[:dest_element])
      rescue => e
        handle_error(e)
        redirect_to admin_collection_edit_all_items_url(col)
      else
        flash['success'] = 'Migrating metadata elements in the background. '\
        'This should take less than a minute.'
        redirect_to admin_collection_edit_all_items_url(col)
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/:item_id/purge-cached-images
    #
    def purge_cached_images
      item = Item.find_by_repository_id(params[:item_id])
      raise ActiveRecord::RecordNotFound unless item
      begin
        item.purge_cached_images
      rescue => e
        handle_error(e)
        redirect_to :back
      else
        flash['success'] = 'All images relating to this item have been purged '\
        'from the image server cache. You may need to clear your browser '\
        'cache to see any changes take effect.'
        redirect_to :back
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
        ReplaceItemMetadataJob.perform_later(
            col.repository_id, params[:matching_mode], params[:find_value],
            params[:element], params[:replace_mode], params[:replace_value])
      rescue => e
        handle_error(e)
        redirect_to admin_collection_edit_all_items_url(col)
      else
        flash['success'] = 'Replacing metadata values in the background. '\
        'This should take less than a minute.'
        redirect_to admin_collection_edit_all_items_url(col)
      end
    end

    ##
    # Responds to GET /admin/collections/:collection_id/items/:id
    #
    def show
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item

      respond_to do |format|
        format.html { @pages = @item.parent ? @item.parent.items : @item.items }
        #format.jsonld { render text: @item.admin_rdf_graph(uri).to_jsonld }
        #format.rdfxml { render text: @item.admin_rdf_graph(uri).to_rdfxml }
        #format.ttl { render text: @item.admin_rdf_graph(uri).to_ttl }
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/sync
    #
    def sync
      col = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless col

      begin
        params[:options] = {} unless params[:options].kind_of?(Hash)
        SyncItemsJob.perform_later(params[:collection_id],
                                   params[:ingest_mode],
                                   params[:options])
      rescue => e
        handle_error(e)
        redirect_to admin_collection_items_url(col)
      else
        flash['success'] = 'Syncing items in the background. This '\
        'may take a while.'
        redirect_to admin_collection_items_url(col)
      end
    end

    def update
      begin
        item = Item.find_by_repository_id(params[:id])
        raise ActiveRecord::RecordNotFound unless item

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
          Solr.instance.commit

          # We will also need to update the effective allowed/denied roles
          # of each child item, which may take some time, so we will do it in
          # the background.
          PropagateRolesToChildrenJob.perform_later(item.repository_id)
        end
      rescue => e
        handle_error(e)
        redirect_to edit_admin_collection_item_path(item.collection, item)
      else
        flash['success'] = "Item \"#{item.title}\" updated."
        redirect_to edit_admin_collection_item_path(item.collection, item)
      end
    end

    ##
    # Responds to POST /admin/items/update
    #
    def update_all
      if params[:items].respond_to?(:each)
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
                  when 'latitude'
                    item.latitude = entry_value.length > 0 ?
                        entry_value.to_f : nil
                  when 'longitude'
                    item.longitude = entry_value.length > 0 ?
                        entry_value.to_f : nil
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
        Solr.instance.commit
        flash['success'] = "#{num_updated} items updated."
      end
      redirect_to :back
    end

    private

    def modify_items_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::Permissions::MODIFY_ITEMS)
    end

    def sanitized_params
      # Metadata elements are not included here, as they are processed
      # separately.
      params.require(:item).permit(:id, :contentdm_alias, :contentdm_pointer,
                                   :embed_tag, :full_text, :latitude,
                                   :longitude, :page_number, :published,
                                   :representative_item_id, :subpage_number,
                                   :variant, allowed_role_ids: [],
                                   denied_role_ids: [])
    end

  end

end
