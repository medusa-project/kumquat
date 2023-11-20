# frozen_string_literal: true

module Admin

  class AgentRelationTypesController < ControlPanelController

    before_action :set_agent_relation_type, except: [:create, :index]
    before_action :authorize_agent_relation_type, except: [:create, :index]

    ##
    # XHR only
    #
    def create
      @type = AgentRelationType.new(sanitized_params)
      authorize(@type)
      begin
        @type.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-Kumquat-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @type }
      rescue => e
        response.headers['X-Kumquat-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'admin/shared/reload'
      else
        response.headers['X-Kumquat-Result'] = 'success'
        flash['success'] = "Agent relation type \"#{@type.name}\" created."
        keep_flash
        render 'admin/shared/reload'
      end
    end

    def destroy
      @type.destroy!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Agent relation type \"#{@type.name}\" deleted."
    ensure
      redirect_to admin_agent_relation_types_path
    end

    ##
    # XHR only
    #
    def edit
      render partial: 'admin/agent_relation_types/form',
             locals: { type: @type }
    end

    ##
    # Responds to GET /admin/agent-relation-types
    #
    def index
      authorize(AgentRelationType)
      @types    = AgentRelationType.all.order(:name)
      @new_type = AgentRelationType.new
    end

    ##
    # XHR only
    #
    def update
      @type.update!(sanitized_params)
    rescue ActiveRecord::RecordInvalid
      response.headers['X-Kumquat-Result'] = 'error'
      render partial: 'shared/validation_messages',
             locals: { entity: @type }
    rescue => e
      response.headers['X-Kumquat-Result'] = 'error'
      handle_error(e)
      keep_flash
      render 'admin/shared/reload'
    else
      response.headers['X-Kumquat-Result'] = 'success'
      flash['success'] = "Agent relation type \"#{@type.name}\" updated."
      keep_flash
      render 'admin/shared/reload'
    end


    private

    def authorize_agent_relation_type
      @type ? authorize(@type) : skip_authorization
    end

    def sanitized_params
      params.require(:agent_relation_type).permit(:description, :name, :uri)
    end

    def set_agent_relation_type
      @type = AgentRelationType.find(params[:id])
    end

  end

end
