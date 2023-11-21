# frozen_string_literal: true

module Admin

  class AgentRulesController < ControlPanelController

    before_action :set_agent_rule, except: [:create, :index]
    before_action :authorize_agent_rule, except: [:create, :index]

    ##
    # XHR only
    #
    def create
      @agent_rule = AgentRule.new(permitted_params)
      authorize(@agent_rule)
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
      @agent_rule.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Agent \"#{@agent_rule.name}\" deleted."
    ensure
      redirect_to admin_agent_rules_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/agent_rules/form',
             locals: { agent_rule: @agent_rule }
    end

    ##
    # Responds to GET /admin/agent-rules
    #
    def index
      authorize(AgentRule)
      @agent_rules    = AgentRule.all.order(:name)
      @new_agent_rule = AgentRule.new
    end

    ##
    # XHR only
    #
    def update
      @agent_rule.update!(permitted_params)
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
      flash['success'] = "Agent \"#{@agent_rule.name}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_agent_rule
      @agent_rule ? authorize(@agent_rule) : skip_authorization
    end

    def permitted_params
      params.require(:agent_rule).permit(:abbreviation, :agent_id, :name)
    end

    def set_agent_rule
      @agent_rule = AgentRule.find(params[:id])
    end

  end

end
