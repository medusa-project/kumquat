module Admin

  class ItemsController < ControlPanelController

    ##
    # Responds to PATCH /admin/items/:web_id/full-text/clear
    #
    def clear_full_text
      @item = Repository::Item.find_by_web_id(params[:repository_item_web_id])
      raise ActiveRecord::RecordNotFound unless @item

      begin
        @item.full_text = nil
        @item.save!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = 'Full text cleared.'
      ensure
        redirect_to admin_repository_item_url(@item)
      end
    end

    def destroy
      @item = Repository::Item.find_by_web_id(params[:web_id])
      raise ActiveRecord::RecordNotFound unless @item

      command = DeleteItemCommand.new(@item)
      begin
        executor.execute(command)
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_repository_item_url(@item)
      else
        flash['success'] = "Item \"#{@item.title}\" deleted."
        redirect_to admin_repository_item_url
      end
    end

    ##
    # Responds to PATCH /admin/items/:web_id/full-text/extract
    #
    def extract_full_text
      @item = Repository::Item.find_by_web_id(params[:repository_item_web_id])
      raise ActiveRecord::RecordNotFound unless @item

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
        redirect_to admin_repository_items_path
        return
      end

      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @items = Repository::Item.all.
          where("-#{Solr::Fields::ITEM}:[* TO *]").
          where(params[:q]).
          facet(false)

      # fields
      field_input_present = false
      if params[:triples] and params[:triples].any?
        params[:triples].each_with_index do |field, index|
          if params[:terms].length > index and !params[:terms][index].blank?
            @items = @items.where("#{field}:#{params[:terms][index]}")
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
        elsif collections.length < Repository::Collection.all.count
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
          @items = @items.order(Solr::Fields::SINGLE_TITLE) unless field_input_present
          @items = @items.start(@start).limit(@limit)
          @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
          @num_results_shown = [@limit, @items.total_length].min

          # these are used by the search form
          @predicates_for_select = Triple.order(:predicate).
              map{ |p| [p.predicate, p.solr_field] }.uniq
          @predicates_for_select.unshift([ 'Any Triple', Solr::Fields::SEARCH_ALL ])
          @collections = Repository::Collection.all
        end
        format.jsonld { stream(RDFStreamer.new(@items, :jsonld), 'export.json') }
        format.rdfxml { stream(RDFStreamer.new(@items, :rdf), 'export.rdf') }
        format.ttl { stream(RDFStreamer.new(@items, :ttl), 'export.ttl') }
      end
    end

    ##
    # Redirects GET /admin/items/search to /admin/items. Also responds to
    # POST /admin/items/search.
    #
    def search
      if request.get?
        redirect_to action: :index, status: 301
      else
        index
        render 'index' unless params[:clear]
      end
    end

    def show
      @item = Repository::Item.find_by_web_id(params[:web_id])
      raise ActiveRecord::RecordNotFound unless @item

      uri = repository_item_url(@item)
      respond_to do |format|
        format.html do
          @pages = @item.parent_item ? @item.parent_item.items : @item.items
        end
        format.jsonld { render text: @item.admin_rdf_graph(uri).to_jsonld }
        format.rdfxml { render text: @item.admin_rdf_graph(uri).to_rdfxml }
        format.ttl { render text: @item.admin_rdf_graph(uri).to_ttl }
      end
    end

    def update
      @item = Repository::Item.find_by_web_id(params[:web_id])
      raise ActiveRecord::RecordNotFound unless @item

      command = UpdateRepositoryItemCommand.new(@item, sanitized_params)
      begin
        executor.execute(command)
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        flash['error'] = "#{e}"
        redirect_to :back
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Item \"#{@item.title}\" updated."
        redirect_to admin_repository_item_url(@item) unless request.xhr?
      end

      render 'show' if request.xhr?
    end

    private

    def sanitized_params
      params.require(:repository_item).permit(:full_text)
    end

  end

end
