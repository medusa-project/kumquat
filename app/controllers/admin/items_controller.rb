module Admin

  class ItemsController < ControlPanelController

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
    # Responds to GET /admin/collections/:collection_id/items
    #
    def index
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      if params[:clear]
        redirect_to admin_collection_items_url(@collection)
        return
      end

      @items = Item.solr.
          where(Item::SolrFields::COLLECTION => @collection.repository_id).
          where(Item::SolrFields::PARENT_ITEM => :null).
          where(params[:q]).facet(false)

      # fields
      field_input_present = false
      if params[:elements] and params[:elements].any?
        params[:elements].each_with_index do |element, index|
          if params[:terms].length > index and !params[:terms][index].blank?
            @items = @items.where("#{element}:#{params[:terms][index]}")
            field_input_present = true
          end
        end
      end

      respond_to do |format|
        format.html do
          if params[:published].present? and params[:published] != 'any'
            @items = @items.where("#{Item::SolrFields::PUBLISHED}:#{params[:published].to_i}")
          end

          @start = params[:start] ? params[:start].to_i : 0
          @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)

          # if there is no user-entered query, sort by title. Otherwise, use
          # the default sort, which is by relevance
          unless field_input_present
            @items = @items.order(ItemElement.named('title').solr_single_valued_field)
          end
          @items = @items.start(@start).limit(@limit)
          @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
          @num_results_shown = [@limit, @items.total_length].min

          # These are used by the search form.
          @elements_for_select = ElementDef.order(:name).
              map{ |p| [p.label, p.solr_multi_valued_field] }.uniq
          @elements_for_select.
              unshift([ 'Any Element', Item::SolrFields::SEARCH_ALL ])
        end
        format.tsv do
          headers['Content-Disposition'] = 'attachment; filename="items.tsv"'
          headers['Content-Disposition'] = 'text/tab-separated-values'
          render text: @collection.items_as_tsv
        end
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/import
    #
    def import
      respond_to do |format|
        format.tsv do
          # Can't pass an uploaded file to an ActiveJob, so it will be saved
          # to this temp file, whose pathname gets passed to the job.
          tempfile = Tempfile.new('peartree-uploaded-items.tsv')
          # The finalizer would otherwise delete it.
          ObjectSpace.undefine_finalizer(tempfile)

          col = Collection.find_by_repository_id(params[:collection_id])
          begin
            raise 'No TSV content specified.' if params[:tsv].blank?
            tsv = params[:tsv].read.force_encoding('UTF-8')
            tempfile.write(tsv)
            tempfile.close
            ImportItemsFromTsvJob.perform_later(tempfile.path)
          rescue => e
            tempfile.unlink
            flash['error'] = "#{e}"
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
    # Responds to GET/POST /admin/collections/:collection_id/items/search
    #
    def search
      index
      render 'index' if !params[:clear] and request.format == :html
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
        SyncItemsJob.perform_later(params[:collection_id],
                                   params[:ingest_mode])
      rescue => e
        flash['error'] = "#{e}"
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
            params[:elements].each do |name, values|
              values.each do |value|
                item.elements.build(name: name, value: value)
              end
            end
            item.save!
          end
        end

        if params[:item]
          item.update!(sanitized_params)
        end
      rescue => e
        flash['error'] = "#{e}"
        redirect_to edit_admin_collection_item_path(item.collection, item)
      else
        flash['success'] = "Item \"#{item.title}\" updated."
        redirect_to edit_admin_collection_item_path(item.collection, item)
      end
    end

    private

    def sanitized_params
      # Metadata elements are not included here, as they are processed
      # separately.
      params.require(:item).permit(:id, :full_text, :latitude, :longitude,
                                   :page_number, :published,
                                   :representative_item_id, :subpage_number,
                                   :variant)
    end

  end

end
