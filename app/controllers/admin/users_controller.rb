module Admin

  class UsersController < ControlPanelController

    before_action :modify_users_rbac, only: [:create, :destroy, :edit, :new,
                                             :update]

    def create
      begin
        user = User.create!(sanitized_params)
      rescue => e
        handle_error(e)
        @user = User.new
        render 'new'
      else
        flash['success'] = "User #{user.username} created."
        redirect_to admin_users_path
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

    def edit
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user
    end

    def index
      @non_human_users = User.where(human: false).order(:username)
    end

    def new
      @user = User.new
    end

    ##
    # Responds to PATCH /users/:username/reset-api-key
    #
    def reset_api_key
      user = User.find_by_username params[:user_username]
      raise ActiveRecord::RecordNotFound unless user

      user.reset_api_key
      begin
        user.save!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Reset API key of #{user.username}."
      ensure
        redirect_back fallback_location: admin_user_path(user)
      end
    end

    def show
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user
    end

    def update
      @user = User.find_by_username params[:username]
      raise ActiveRecord::RecordNotFound unless @user

      begin
        @user.update_attributes!(sanitized_params)
      rescue => e
        handle_error(e)
        render 'edit'
      else
        flash['success'] = "User #{@user.username} updated."
        redirect_to admin_users_path
      end
    end

    private

    def modify_users_rbac
      redirect_to(admin_root_url) unless
          current_user.can?(Permissions::MODIFY_USERS)
    end

    def sanitized_params
      params.require(:user).permit(:human, :username, role_ids: [])
    end

  end

end