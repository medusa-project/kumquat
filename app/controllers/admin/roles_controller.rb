module Admin

  class RolesController < ControlPanelController

    before_action :create_roles_rbac, only: [:new, :create]
    before_action :delete_roles_rbac, only: :destroy
    before_action :update_roles_rbac, only: [:edit, :update]

    def create
      command = CreateRoleCommand.new(sanitized_params)
      @role = command.object
      begin
        executor.execute(command)
      rescue => e
        flash[:error] = "#{e}"
        render 'new'
      else
        flash[:success] = "Role \"#{@role.name}\" created."
        redirect_to admin_role_url(@role)
      end
    end

    def destroy
      @role = Role.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @role

      command = DeleteRoleCommand.new(@role)
      begin
        executor.execute(command)
      rescue => e
        flash[:error] = "#{e}"
        redirect_to admin_role_url(@role)
      else
        flash[:success] = "Role \"#{@role.name}\" deleted."
        redirect_to admin_roles_url
      end
    end

    def edit
      @role = Role.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @role
      @users = User.order(:username)
    end

    def index
      @roles = Role.order(:name)
    end

    def new
      @role = Role.new
      @users = User.order(:username)
    end

    def show
      @role = Role.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @role

      @permissions = Permission.order(:key)
    end

    def update
      @role = Role.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless @role

      command = UpdateRoleCommand.new(@role, sanitized_params)
      begin
        executor.execute(command)
      rescue => e
        @users = User.order(:username)
        flash[:error] = "#{e}"
        render 'edit'
      else
        flash[:success] = "Role \"#{@role.name}\" updated."
        redirect_to admin_role_url(@role)
      end
    end

    private

    def create_roles_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::CREATE_ROLE)
    end

    def delete_roles_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::DELETE_ROLE)
    end

    def sanitized_params
      params.require(:role).permit(:key, :name, permission_ids: [],
                                   user_ids: [])
    end

    def update_roles_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::UPDATE_ROLE)
    end

  end

end
