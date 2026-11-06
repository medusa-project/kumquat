# frozen_string_literal: true

module Admin 

  class ItemEventsController < ControlPanelController
    # read item events with {index} and {show} actions
    
    ## 
    # Responds to GET /admin/item_events
    #
    def index 
      authorize(ItemEvent)
      @item_events = ItemEvent.preload(:item, :user).
          order(created_at: :desc, id: :desc)
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