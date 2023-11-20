# frozen_string_literal: true

module Admin

  class UsersController < ControlPanelController

    before_action :set_user, except: [:create, :index, :new]
    before_action :authorize_user, except: [:create, :index, :new]

    def create
      user = User.new(sanitized_params)
      authorize(user)
      begin
        user.save!
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
      @user.destroy!
    rescue => e
      handle_error(e)
      redirect_to admin_users_url
    else
      if @user == current_user
        flash['success'] = 'Your account has been deleted.'
        sign_out
        redirect_to root_url
      else
        flash['success'] = "User #{@user.username} deleted."
        redirect_to admin_users_url
      end
    end

    def index
      @non_human_users = User.where(human: false).order(:username)
    end

    def new
      @user = User.new
    end

    ##
    # Responds to POST /users/:username/reset-api-key
    #
    def reset_api_key
      @user.reset_api_key
      @user.save!
    rescue => e
      handle_error(e)
    else
      flash['success'] = "Reset API key of #{@user.username}."
    ensure
      redirect_back fallback_location: admin_user_path(@user)
    end

    def show
    end


    private

    def authorize_user
      @user ? authorize(@user) : skip_authorization
    end

    def sanitized_params
      params.require(:user).permit(:human, :username, role_ids: [])
    end

    def set_user
      @user = User.find_by_username(params[:username] || params[:user_username])
      raise ActiveRecord::RecordNotFound unless @user
    end

  end

end
