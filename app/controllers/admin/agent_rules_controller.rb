module Admin

  class AgentRulesController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @agent_rule = AgentRule.new(sanitized_params)
      begin
        @agent_rule.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_rule }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent rule \"#{@agent_rule.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      agent_rule = AgentRule.find(params[:id])
      begin
        agent_rule.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Agent \"#{agent_rule.name}\" deleted."
      ensure
        redirect_to admin_agent_rules_path
      end
    end

    ##
    # XHR only
    #
    def edit
      agent_rule = AgentRule.find(params[:id])
      render partial: 'admin/agent_rules/form',
             locals: { agent_rule: agent_rule }
    end

    ##
    # Responds to GET /admin/agent-rules
    #
    def index
      @agent_rules    = AgentRule.all.order(:name)
      @new_agent_rule = AgentRule.new
    end

    ##
    # XHR only
    #
    def update
      agent_rule = AgentRule.find(params[:id])
      begin
        agent_rule.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent_rule }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent \"#{agent_rule.name}\" updated."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    private

    def sanitized_params
      params.require(:agent_rule).permit(:abbreviation, :agent_id, :name)
    end

  end

end
