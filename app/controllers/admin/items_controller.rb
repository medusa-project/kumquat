module Admin

  class ItemsController < ControlPanelController

    ##
    # Responds to GET /admin/collections/:collection_id/items
    #
    def index
      @collection = Collection.find_by_repository_id(params[:collection_id])
      raise ActiveRecord::RecordNotFound unless @collection

      if params[:clear]
        redirect_to edit_admin_collection_item_url(@collection)
        return
      end

      @items = Item.solr.
          where(Item::SolrFields::COLLECTION => @collection.repository_id).
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
            @items = @items.order(Element.named('title').solr_single_valued_field)
          end
          @items = @items.where(Item::SolrFields::PARENT_ITEM => :null).
              start(@start).limit(@limit)
          @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
          @num_results_shown = [@limit, @items.total_length].min

          # These are used by the search form.
          @elements_for_select = ElementDef.order(:name).
              map{ |p| [p.label, p.solr_multi_valued_field] }.uniq
          @elements_for_select.
              unshift([ 'Any Element', Item::SolrFields::SEARCH_ALL ])
        end
        format.tsv do
          # The TSV representation includes item children. Ordering, limit,
          # offset, etc. is not customizable.

          # Here we use Enumerator in conjunction with some custom headers to
          # stream the results, as an alternative to send_data
          # which would require them to be loaded into memory first.
          enumerator = Enumerator.new do |y|
            y << Item.tsv_header(@collection.effective_metadata_profile)
            # Item.uncached disables ActiveRecord caching that would prevent
            # previous find_each batches from being garbage-collected.
            Item.uncached do
              @items.order(Item::SolrFields::ID).
                  find_each { |item| y << item.to_tsv }
            end
          end
          stream(enumerator, 'items.tsv')
        end
      end
    end

    ##
    # Responds to POST /admin/collections/:collection_id/items/ingest
    #
    def ingest
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
            tempfile.write(params[:tsv].read)
            tempfile.close
            IngestItemsFromTsvJob.perform_later(tempfile.path,
                                                params[:collection_id])
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

  end

end
