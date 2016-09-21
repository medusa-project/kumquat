module Admin

  class RolesController < ControlPanelController

    before_action :modify_roles_rbac, only: [:new, :create, :destroy, :edit,
                                             :update]

    def create
      @role = Role.new(sanitized_params)
      begin
        ActiveRecord::Base.transaction do
          # Hosts from the form textarea need to be processed manually.
          params[:role][:hosts].split("\n").each do |pattern|
            @role.hosts.build(pattern: pattern.strip)
          end
          @role.save!
        end
      rescue => e
        @users = User.order(:username)
        flash[:error] = "#{e}"
        render 'new'
      else
        flash[:success] = "Role \"#{@role.name}\" created."
        redirect_to admin_role_url(@role)
      end
    end

    def destroy
      role = Role.find_by_key(params[:key])
      raise ActiveRecord::RecordNotFound unless role
      begin
        role.destroy!
      rescue => e
        flash[:error] = "#{e}"
        redirect_to admin_role_url(role)
      else
        flash[:success] = "Role \"#{role.name}\" deleted."
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

      begin
        ActiveRecord::Base.transaction do
          # Hosts from the form textarea need to be processed manually.
          @role.hosts.destroy_all
          params[:role][:hosts].split("\n").each do |pattern|
            @role.hosts.build(pattern: pattern.strip)
          end
          @role.update_attributes!(sanitized_params)
        end
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

    def modify_roles_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::Permissions::MODIFY_ROLES)
    end

    def sanitized_params
      params.require(:role).permit(:key, :name, permission_ids: [],
                                   user_ids: [])
    end

  end

end
