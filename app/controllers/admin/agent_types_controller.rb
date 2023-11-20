# frozen_string_literal: true

module Admin

  class AgentTypesController < ControlPanelController

    before_action :set_agent_type, except: [:create, :index]
    before_action :authorize_agent_type, except: [:create, :index]

    ##
    # XHR only
    #
    def create
      @agent_type = AgentType.new(sanitized_params)
      authorize(@agent_type)
      begin
        @agent_type.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_type }
      rescue => e
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent type \"#{@agent_type.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      @agent_type.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Agent type \"#{@agent_type.name}\" deleted."
    ensure
      redirect_to admin_agent_types_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/agent_types/form',
             locals: { agent_type: @agent_type }
    end

    ##
    # Responds to GET /admin/agent-types
    #
    def index
      authorize(AgentType)
      @agent_types    = AgentType.all.order(:name)
      @new_agent_type = AgentType.new
    end

    ##
    # XHR only
    #
    def update
      @agent_type.update!(sanitized_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @agent_type }
    rescue => e
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Agent type \"#{@agent_type.name}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_agent_type
      @agent_type ? authorize(@agent_type) : skip_authorization
    end

    def sanitized_params
      params.require(:agent_type).permit(:agent_id, :name)
    end

    def set_agent_type
      @agent_type = AgentType.find(params[:id])
    end

  end

end
