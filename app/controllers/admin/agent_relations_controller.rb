# frozen_string_literal: true

module Admin

  class AgentRelationsController < ControlPanelController

    before_action :set_agent_relation, except: :create
    before_action :authorize_agent_relation, except: :create

    ##
    # XHR only
    #
    def create
      p = permitted_params
      if p[:agent_id].present?
        p[:agent_id] = Agent.find_by_name(p[:agent_id])&.id
      end
      if p[:related_agent_id].present?
        p[:related_agent_id] = Agent.find_by_name(p[:related_agent_id])&.id
      end
      @agent_relation = AgentRelation.new(p)
      authorize(@agent_relation)
      begin
        ActiveRecord::Base.transaction { @agent_relation.save! }
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_relation }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = 'Agent relationship created.'
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      ActiveRecord::Base.transaction { @agent_relation.destroy! }
    rescue => e
      handle_error(e)
    else
      flash['success'] = 'Agent relationship removed.'
    ensure
      redirect_back fallback_location: admin_agent_relations_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/agent_relations/relating_agent_form',
             locals:  { agent_relation: @agent_relation }
    end

    ##
    # XHR only
    #
    def update
      p = permitted_params
      if p[:agent_id].present?
        p[:agent_id] = Agent.find_by_name(p[:agent_id])&.id
      end
      if p[:related_agent_id].present?
        p[:related_agent_id] = Agent.find_by_name(p[:related_agent_id])&.id
      end
      ActiveRecord::Base.transaction { @agent_relation.update!(p) }
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @agent_relation }
    rescue => e
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: e }
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = 'Agent relationship updated.'
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_agent_relation
      @agent_relation ? authorize(@agent_relation) : skip_authorization
    end

    def permitted_params
      params.require(:agent_relation).permit(:agent_id, :agent_relation_type_id,
                                             :dates, :description,
                                             :related_agent_id)
    end

    def set_agent_relation
      @agent_relation = AgentRelation.find(params[:id])
    end

  end

end
