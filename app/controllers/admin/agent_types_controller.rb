module Admin

  class AgentTypesController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @agent_type = AgentType.new(sanitized_params)
      begin
        @agent_type.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent_type }
      rescue => e
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent type \"#{@agent_type.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      agent_type = AgentType.find(params[:id])
      begin
        agent_type.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Agent type \"#{agent_type.name}\" deleted."
      ensure
        redirect_to admin_agent_types_path
      end
    end

    ##
    # XHR only
    #
    def edit
      agent_type = AgentType.find(params[:id])
      render partial: 'admin/agent_types/form',
             locals: { agent_type: agent_type, context: :edit }
    end

    ##
    # Responds to GET /admin/agent-types
    #
    def index
      @agent_types = AgentType.all.order(:name)
      @new_agent_type = AgentType.new
    end

    ##
    # XHR only
    #
    def update
      agent_type = AgentType.find(params[:id])
      begin
        agent_type.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent_type }
      rescue => e
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent type \"#{agent_type.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:agent_type).permit(:agent_id, :name)
    end

  end

end
