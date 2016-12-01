module Admin

  class AgentRelationTypesController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @type = AgentRelationType.new(sanitized_params)
      begin
        @type.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @type }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent relation type \"#{@type.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      type = AgentRelationType.find(params[:id])
      begin
        type.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Agent relation type \"#{type.name}\" deleted."
      ensure
        redirect_to admin_agent_relation_types_path
      end
    end

    ##
    # XHR only
    #
    def edit
      type = AgentRelationType.find(params[:id])
      render partial: 'admin/agent_relation_types/form',
             locals: { type: type, context: :edit }
    end

    ##
    # Responds to GET /admin/agent-relation-types
    #
    def index
      @types = AgentRelationType.all.order(:name)
      @new_type = AgentRelationType.new
    end

    ##
    # XHR only
    #
    def update
      type = AgentRelationType.find(params[:id])
      begin
        type.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: type }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent relation type \"#{type.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:agent_relation_type).permit(:description, :name)
    end

  end

end
