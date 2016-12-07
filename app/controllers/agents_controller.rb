class AgentsController < WebsiteController

  ##
  # Responds to GET /agents/:id
  #
  def show
    if Socket.gethostname.start_with?('kumquat-prod')
      render text: 'Agents are not yet available in production.', status: 403
      return
    end

    @agent = Agent.find(params[:id])
    fresh_when(etag: @agent) if Rails.env.production?

    @related_agents = @agent.related_agents
    @related_objects = @agent.related_objects # TODO: respect authorization
    @related_collections = @agent.related_collections # TODO: respect authorization

    respond_to do |format|
      format.html
      format.json do
        render json: @agent.decorate(context: {
            related_objects: @related_objects,
            related_agents: @related_agents,
            related_collections: @related_collections })
        end
    end
  end

end
