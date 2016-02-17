module Admin

  class ItemsController < ControlPanelController

    ##
    # Responds to PATCH /admin/items/:id/full-text/clear
    #
    def clear_full_text
      @item = Item.find(params[:item_id])
      begin
        @item.full_text = nil
        @item.save!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = 'Full text cleared.'
      ensure
        redirect_to admin_item_url(@item)
      end
    end

    ##
    # Responds to PATCH /admin/items/:id/full-text/extract
    #
    def extract_full_text
      @item = Item.find(params[:item_id])

      args = {
          command: ExtractFullTextCommand,
          args: @item,
          task_status_text: "Extract full text from item \"#{@item.title}\""
      }
      @job_runner.run_later(CommandJob, args)

      flash['success'] = 'Queued full text extraction. This may take a while '\
      'depending on the size of the master bytestream.'
      redirect_to :back
    end

    def index
      if params[:clear]
        redirect_to admin_items_path
        return
      end

      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @items = Item.all.where(Solr::Fields::PARENT_ITEM => :null).
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

      # collections
      collections = []
      collections = params[:collections].select{ |k| !k.blank? } if
          params[:collections] and params[:collections].any?
      if collections.any?
        if collections.length == 1
          @items = @items.where("#{Solr::Fields::COLLECTION}:\"#{collections.first}\"")
        elsif collections.length < Collection.all.count
          @items = @items.where("#{Solr::Fields::COLLECTION}:(#{collections.join(' ')})")
        end
      end

      if params[:published].present? and params[:published] != 'any'
        @items = @items.where("#{Solr::Fields::PUBLISHED}:#{params[:published].to_i}")
      end

      respond_to do |format|
        format.html do
          # if there is no user-entered query, sort by title. Otherwise, use
          # the default sort, which is by relevancy
          @items = @items.order(Solr::Fields::TITLE) unless field_input_present
          @items = @items.start(@start).limit(@limit)
          @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
          @num_results_shown = [@limit, @items.total_length].min

          # these are used by the search form
          #@elements_for_select = ElementDef.order(:name).
          #    map{ |p| [p.name, p.solr_field] }.uniq
          @elements_for_select = ElementDef.order(:name).
              map{ |p| [p.label, nil] }.uniq
          @elements_for_select.unshift([ 'Any Element', Solr::Fields::SEARCH_ALL ])
          @collections = Collection.all
        end
        #format.jsonld { stream(RDFStreamer.new(@items, :jsonld), 'export.json') }
        #format.rdfxml { stream(RDFStreamer.new(@items, :rdf), 'export.rdf') }
        #format.ttl { stream(RDFStreamer.new(@items, :ttl), 'export.ttl') }
      end
    end

    ##
    # Responds to GET/POST /admin/items/search
    #
    def search
      index
      render 'index' unless params[:clear]
    end

    def show
      @item = Item.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @item

      respond_to do |format|
        format.html do
          @pages = @item.parent ? @item.parent.items : @item.items
        end
        #format.jsonld { render text: @item.admin_rdf_graph(uri).to_jsonld }
        #format.rdfxml { render text: @item.admin_rdf_graph(uri).to_rdfxml }
        #format.ttl { render text: @item.admin_rdf_graph(uri).to_ttl }
      end
    end

    private

    def sanitized_params
      params.require(:item).permit(:full_text)
    end

  end

end
