module Harvest

  class AgentsController < AbstractHarvestController

    before_action :load_agent

    ##
    # Responds to GET /harvest/agents/:id
    #
    def show
      @agent_relations = AgentRelation.related_to_agent(@agent)
      @related_objects = @agent.related_objects.
          order(:repository_id).offset(@start).
          limit(@limit).to_a
      @related_collections = @agent.related_collections

      render json: @agent.decorate(context: {
          agent_relations: @agent_relations,
          related_objects: @related_objects,
          related_collections: @related_collections })
    end

    private

    def load_agent
      @agent = Agent.find(params[:agent_id] || params[:id])
      raise ActiveRecord::RecordNotFound unless @agent
    end

  end

end
