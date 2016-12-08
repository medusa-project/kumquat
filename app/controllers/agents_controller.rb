class AgentsController < WebsiteController

  ##
  # Responds to GET /agents/:id
  #
  def show
    @agent = Agent.find(params[:id])
    fresh_when(etag: @agent) if Rails.env.production?

    @agent_relations = AgentRelation.related_to_agent(@agent)
    @related_objects = @agent.related_objects # TODO: respect authorization
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

end
