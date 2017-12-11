module Admin

  class AgentRelationsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      p = sanitized_params
      if p[:agent_id].present?
        p[:agent_id] = Agent.find_by_name(p[:agent_id])&.id
      end
      if p[:related_agent_id].present?
        p[:related_agent_id] = Agent.find_by_name(p[:related_agent_id])&.id
      end
      @agent_relation = AgentRelation.new(p)
      begin
        ActiveRecord::Base.transaction { @agent_relation.save! }
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_relation }
      rescue => e
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = 'Agent relationship created.'
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      agent_relation = AgentRelation.find(params[:id])
      begin
        ActiveRecord::Base.transaction { agent_relation.destroy! }
      rescue => e
        handle_error(e)
      else
        flash['success'] = 'Agent relationship removed.'
      ensure
        redirect_back fallback_location: admin_agent_relations_path
      end
    end

    ##
    # XHR only
    #
    def edit
      agent_relation = AgentRelation.find(params[:id])
      render partial: 'admin/agent_relations/relating_agent_form',
             locals: { agent_relation: agent_relation,
                       context: :edit }
    end

    ##
    # XHR only
    #
    def update
      agent_relation = AgentRelation.find(params[:id])
      begin
        p = sanitized_params
        if p[:agent_id].present?
          p[:agent_id] = Agent.find_by_name(p[:agent_id])&.id
        end
        if p[:related_agent_id].present?
          p[:related_agent_id] = Agent.find_by_name(p[:related_agent_id])&.id
        end
        ActiveRecord::Base.transaction { agent_relation.update!(p) }
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent_relation }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: e }
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = 'Agent relationship updated.'
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:agent_relation).permit(:agent_id, :agent_relation_type_id,
                                             :dates, :description,
                                             :related_agent_id)
    end

  end

end
