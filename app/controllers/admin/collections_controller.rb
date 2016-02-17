module Admin

  class CollectionsController < ControlPanelController

    def index
      @start = params[:start] ? params[:start].to_i : 0
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @collections = Collection.
          order(Element.named('title').solr_single_valued_field).
          start(@start).limit(@limit)
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1
      @num_shown = [@limit, @collections.total_length].min
      @collection = Collection.new
    end

    def show
      @collection = Collection.find(params[:id])
    end

  end

end
