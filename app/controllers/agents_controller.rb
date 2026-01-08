class AgentsController < WebsiteController

  ITEMS_LIMIT = 30

  before_action :set_permitted_params, only: :show
  before_action :set_agent
  before_action :authorize_agent

  ##
  # Responds to GET /agent/:id/items (XHR only)
  #
  def items
    if request.xhr?
      set_items_ivars
      render "items"
    else
      render plain: "Not Acceptable", status: :not_acceptable
    end
  end

  ##
  # Responds to GET /agents/:id
  #
  def show
    @agent_relations = AgentRelation.related_to_agent(@agent)
    set_items_ivars
    @related_collections = @agent.related_collections # TODO: respect authorization

    respond_to do |format|
      format.html
      format.json do
        render json: @agent.decorate(context: {
            agent_relations: @agent_relations,
            related_objects: @related_objects,
            related_collections: @related_collections })
        end
    end
  end


  private

  def authorize_agent
    @agent ? authorize(@agent) : skip_authorization
  end

  def set_agent
    @agent = Agent.find(params[:agent_id] || params[:id])
    raise ActiveRecord::RecordNotFound unless @agent
  end

  def set_items_ivars
    @start                = params[:start] ? params[:start].to_i : 0
    @limit                = ITEMS_LIMIT
    @current_page         = (@start / @limit.to_f).ceil + 1 if @limit > 0
    # TODO: respect authorization
    @related_objects      = @agent.related_objects
    @related_object_count = @related_objects.count
    @related_objects      = @related_objects.order(:repository_id).
        offset(@start).limit(@limit).to_a
  end

  def set_permitted_params
    @permitted_params = params.permit([])
  end

end
