module Admin

  class AgentsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @agent = Agent.new(sanitized_agent_params)
      begin
        ActiveRecord::Base.transaction do
          params[:agent_uris].select{ |k, v| v[:uri]&.present? }.each do |k, v|
            @agent.agent_uris.build(uri: v[:uri],
                                    primary: (v[:primary] == 'true'))
          end
          @agent.save!

          if params[:agent_relation]
            relation = AgentRelation.new(sanitized_agent_relation_params)
            relation.related_agent = @agent
            relation.save!
          end
        end
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handlbunde_error(e)
        keep_flash
        render 'create'
      else
        Solr.instance.commit
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent \"#{@agent.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      agent = Agent.find(params[:id])
      begin
        ActiveRecord::Base.transaction { agent.destroy! }
      rescue => e
        handle_error(e)
      else
        Solr.instance.commit
        flash['success'] = "Agent \"#{agent.name}\" deleted."
      ensure
        redirect_to admin_agents_path
      end
    end

    ##
    # XHR only
    #
    def edit
      agent = Agent.find(params[:id])
      render partial: 'admin/agents/form',
             locals: { agent: agent, context: :edit }
    end

    ##
    # Responds to GET /admin/agents
    #
    def index
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @start = params[:start] ? params[:start].to_i : 0
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1

      @agents = Agent.all.order(:name).offset(@start).limit(@limit)

      if params[:q].present?
        @agents = @agents.where('LOWER(name) LIKE ?', "%#{params[:q].downcase}%")
      end

      @new_agent = Agent.new
      @new_agent.agent_uris.build
    end

    ##
    # Responds to GET /admin/agents/:id
    #
    def show
      @agent = Agent.find(params[:id])
      @new_agent = Agent.new
      @new_agent.agent_uris.build
      @new_agent_relation = @agent.agent_relations.build
      @relating_agents = AgentRelation.where(related_agent: @agent)
      @related_agents = AgentRelation.where(agent: @agent)

      @num_item_references = Item.
          joins('LEFT JOIN entity_elements ON entity_elements.item_id = items.id').
          where('entity_elements.uri IN (?)', @agent.agent_uris.map(&:uri)).count
      @num_collection_references = 0 # TODO: fix
      @num_agent_references = @relating_agents.count + @related_agents.count
    end

    ##
    # XHR only
    #
    def update
      agent = Agent.find(params[:id])
      begin
        ActiveRecord::Base.transaction do
          agent.agent_uris.destroy_all
          params[:agent_uris].select{ |k, v| v[:uri]&.present? }.each do |k, v|
            agent.agent_uris.build(uri: v[:uri],
                                   primary: (v[:primary] == 'true'))
          end
          agent.update!(sanitized_agent_params)
        end
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: e }
      else
        Solr.instance.commit
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent \"#{agent.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_agent_params
      params.require(:agent).permit(:agent_rule_id, :agent_type_id,
                                    :description, :name, :uri)
    end

    def sanitized_agent_relation_params
      params.require(:agent_relation).permit(:agent_id, :related_agent_id,
                                             :agent_relation_type_id)
    end

  end

end
