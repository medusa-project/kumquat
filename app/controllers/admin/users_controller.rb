module Admin

  class UsersController < ControlPanelController

    before_action :modify_users_rbac, only: [:change_roles, :create, :destroy,
                                             :disable, :enable, :edit, :update]

    ##
    # Responds to PATCH /users/:username/roles. Supply :do => :join/:leave
    # and :role_id params.
    #
    def change_roles
      user = User.find_by_username params[:user_username]
      raise ActiveRecord::RecordNotFound unless user

      role_ids = user.roles.map(&:id)
      if params[:do].to_s == 'join'
        role_ids << params[:role_id].to_i
      else
        role_ids.delete(params[:role_id].to_i)
      end

      tmp_params = sanitized_params
      tmp_params[:role_ids] = role_ids
      begin
        user.update_attributes!(tmp_params)
      rescue => e
        handle_error(e)
        render 'new'
      else
        flash['success'] = "User #{user.username} updated."
        redirect_back fallback_location: admin_user_path(user)
      end
    end

    def create
      begin
        user = User.create!(sanitized_params)
      rescue => e
        handle_error(e)
        @user = User.new
        @roles = Role.all.order(:name)
        render 'new'
      else
        flash['success'] = "User #{user.username} created."
        redirect_to admin_user_path(user)
      end
    end

    def destroy
      user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless user

      begin
        user.destroy!
      rescue => e
        handle_error(e)
        redirect_to admin_users_url
      else
        if user == current_user
          flash['success'] = 'Your account has been deleted.'
          sign_out
          redirect_to root_url
        else
          flash['success'] = "User #{user.username} deleted."
          redirect_to admin_users_url
        end
      end
    end

    ##
    # Responds to PATCH /users/:username/disable
    #
    def disable
      user = User.find_by_username params[:user_username]
      raise ActiveRecord::RecordNotFound unless user

      user.enabled = false
      begin
        user.save!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "User #{user.username} disabled."
      ensure
        redirect_back fallback_location: admin_user_path(user)
      end
    end

    def edit
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user
      @roles = Role.all.order(:name)
    end

    ##
    # Responds to PATCH /users/:username/enable
    #
    def enable
      user = User.find_by_username params[:user_username]
      raise ActiveRecord::RecordNotFound unless user

      user.enabled = true
      begin
        user.save!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "User #{user.username} enabled."
      ensure
        redirect_back fallback_location: admin_user_path(user)
      end
    end

    def index
      q = "%#{params[:q]}%"
      @users = User.where('users.username LIKE ?', q).order('username')
    end

    def new
      @user = User.new
      @roles = Role.all.order(:name)
    end

    def show
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user
      @permissions = Permission.order(:key)
    end

    def update
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user

      begin
        @user.update_attributes!(sanitized_params)
      rescue => e
        @roles = Role.all.order(:name)
        handle_error(e)
        render 'edit'
      else
        flash['success'] = "User #{@user.username} updated."
        redirect_to admin_user_path(@user)
      end
    end

    private

    def modify_users_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permission::Permissions::MODIFY_USERS)
    end

    def sanitized_params
      params.require(:user).permit(:enabled, :username, role_ids: [])
    end

  end

end