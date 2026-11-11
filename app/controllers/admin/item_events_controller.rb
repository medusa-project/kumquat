# frozen_string_literal: true

module Admin 

  class ItemEventsController < ControlPanelController
    PERMITTED_SEARCH_PARAMS = [:start, :q, :commit]

    # read item events with {index} and {show} actions
    
    ## 
    # Responds to GET /admin/item_events
    #
    def index 
      authorize(ItemEvent)
      @limit = Setting::integer(Setting::Keys::DEFAULT_RESULT_WINDOW)
      @start = params[:start] ? params[:start].to_i : 0
      @start = 0 if @start < 0
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0

      events = ItemEvent.preload(:item, :user).
          order(created_at: :desc, id: :desc)

      if params[:q].present?
        query = "%#{Item.sanitize_sql_like(params[:q])}%"
        events = events.joins(:item, :user).where(
          "users.username ILIKE :query OR " \
          "items.repository_id ILIKE :query OR " \
          "EXISTS (SELECT 1 FROM entity_elements " \
          "WHERE entity_elements.item_id = items.id " \
          "AND entity_elements.name = 'title' " \
          "AND entity_elements.value ILIKE :query) OR " \
          "EXISTS (SELECT 1 FROM jsonb_object_keys(item_events.changeset) " \
          "AS changed_fields(field_name) " \
          "WHERE changed_fields.field_name ILIKE :query)",
          query: query
        )
      end
      @count = events.count
      @item_events = events.offset(@start).limit(@limit)
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