module Admin

  class AgentsController < ControlPanelController

    PERMITTED_PARAMS = [:agent_rule_id, :agent_type_id, :description,
                        :name, :uri]

    ##
    # XHR only
    #
    def create
      @agent = Agent.new(sanitized_params)
      begin
        ActiveRecord::Base.transaction do
          params[:agent_uris].select{ |k, v| v[:uri]&.present? }.each do |k, v|
            @agent.agent_uris.build(uri: v[:uri],
                                    primary: (v[:primary] == 'true'))
          end
          @agent.save!

        end
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent \"#{@agent.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      agent = Agent.find(params[:id])
      begin
        ActiveRecord::Base.transaction { agent.destroy! }
      rescue => e
        handle_error(e)
      else
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
             locals: { agent: agent }
    end

    ##
    # Responds to GET /admin/agents
    #
    def index
      @limit        = Option::integer(Option::Keys::DEFAULT_RESULT_WINDOW)
      @start        = params[:start] ? params[:start].to_i : 0
      @current_page = (@start / @limit.to_f).ceil + 1 if @limit > 0 || 1

      @agents = Agent.all.order(:name)

      if params[:q].present?
        q = "%#{params[:q].downcase}%"
        @agents = @agents.select('DISTINCT(agents.*)').
            joins('LEFT JOIN agent_uris ON agent_uris.agent_id = agents.id').
            where('LOWER(name) LIKE ? OR LOWER(agent_uris.uri) LIKE ?', q, q)
      end

      respond_to do |format|
        format.html do
          @agent_count = @agents.count
          @agents = @agents.offset(@start).limit(@limit)
          @new_agent = Agent.new
          @new_agent.agent_uris.build
        end
        format.js do
          @agent_count = @agents.count
          @agents = @agents.offset(@start).limit(@limit)
        end
        format.json do
          @agents = @agents.offset(0).limit(10)
          render json: @agents
        end
      end
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
          where('entity_elements.uri IN (?)', @agent.agent_uris.pluck(:uri)).count
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
          agent.update!(sanitized_params)
        end
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: e }
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent \"#{agent.name}\" updated."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    private

    def sanitized_params
      params.require(:agent).permit(PERMITTED_PARAMS)
    end

  end

end
