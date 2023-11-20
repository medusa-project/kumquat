# frozen_string_literal: true

module Admin

  class HostGroupsController < ControlPanelController

    before_action :set_host_group, except: [:create, :index, :new]
    before_action :authorize_host_group, except: [:create, :index, :new]

    def create
      @host_group = HostGroup.new(sanitized_params)
      authorize(@host_group)
      begin
        @host_group.save!
      rescue => e
        flash['error'] = "#{e}"
        render 'new'
      else
        flash['success'] = "Host group \"#{@host_group.name}\" created."
        redirect_to admin_host_groups_path
      end
    end

    def destroy
      @host_group.destroy!
    rescue => e
      flash['error'] = "#{e}"
      redirect_to admin_host_group_path(@host_group)
    else
      flash['success'] = "Host group \"#{@host_group.name}\" deleted."
      redirect_to admin_host_groups_path
    end

    def edit
    end

    def index
      authorize(HostGroup)
      @host_groups = HostGroup.order(:name)
    end

    def new
      @host_group = HostGroup.new
      authorize(@host_group)
    end

    def show
    end

    def update
      @host_group.update!(sanitized_params)
    rescue => e
      flash['error'] = "#{e}"
      render 'edit'
    else
      flash['success'] = "Host group \"#{@host_group.name}\" updated."
      redirect_to admin_host_groups_url
    end


    private

    def authorize_host_group
      @host_group ? authorize(@host_group) : skip_authorization
    end

    def sanitized_params
      params.require(:host_group).permit(:key, :name, :pattern)
    end

    def set_host_group
      @host_group = HostGroup.find(params[:id])
    end

  end

end
