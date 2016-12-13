module Admin

  class AgentRelationsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      p = sanitized_params
      p[:related_agent_id] = Agent.find_by_name(p[:related_agent_id]).id
      @agent_relation = AgentRelation.new(p)
      begin
        ActiveRecord::Base.transaction { @agent_relation.save! }
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_relation }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        Solr.instance.commit
        response.headers['X-PearTree-Result'] = 'success'
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
        Solr.instance.commit
        flash['success'] = 'Agent relationship removed.'
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      agent_relation = AgentRelation.find(params[:id])
      render partial: 'admin/agent_relations/form',
             locals: { agent: agent_relation.agent,
                       agent_relation: agent_relation,
                       context: :edit }
    end

    ##
    # XHR only
    #
    def update
      agent_relation = AgentRelation.find(params[:id])
      begin
        ActiveRecord::Base.transaction do
          agent_relation.update!(sanitized_params)
        end
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent_relation }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: e }
      else
        Solr.instance.commit
        response.headers['X-PearTree-Result'] = 'success'
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
