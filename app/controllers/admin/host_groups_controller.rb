module Admin

  class HostGroupsController < ControlPanelController

    def create
      @host_group = HostGroup.new(sanitized_params)
      begin
        @host_group.save!
      rescue => e
        flash['error'] = "#{e}"
        render 'new'
      else
        flash['success'] = "Host group \"#{@host_group.name}\" created."
        redirect_to admin_host_groups_url
      end
    end

    def destroy
      group = HostGroup.find(params[:id])
      begin
        group.destroy!
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_host_group_url(group)
      else
        flash['success'] = "Host group \"#{group.name}\" deleted."
        redirect_to admin_host_groups_url
      end
    end

    def edit
      @host_group = HostGroup.find(params[:id])
    end

    def index
      @host_groups = HostGroup.order(:name)
    end

    def new
      @host_group = HostGroup.new
    end

    def show
      @host_group = HostGroup.find(params[:id])
    end

    def update
      @host_group = HostGroup.find(params[:id])
      begin
        @host_group.update!(sanitized_params)
      rescue => e
        flash['error'] = "#{e}"
        render 'edit'
      else
        flash['success'] = "Host group \"#{@host_group.name}\" updated."
        redirect_to admin_host_groups_url
      end
    end

    private

    def sanitized_params
      params.require(:host_group).permit(:key, :name, :pattern)
    end

  end

end
