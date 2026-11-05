# frozen_string_literal: true

module Admin 

  class ItemEventsController < ControlPanelController
    # read item events with {index} and {show} actions
    
    ## 
    # Responds to GET /admin/item_events
    #
    def index 
      authorize(ItemEvent)
      #todo
    end

    ##
    # Responds to GET /admin/item_events/:id
    #
    def show
      @item_event = ItemEvent.find(params[:id])
      authorize(@item_event)
      #todo
    end

  end

end