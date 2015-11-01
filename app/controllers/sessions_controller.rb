class SessionsController < WebsiteController

  ##
  # Responds to POST /auth/:provider/callback
  #
  def create
    auth_hash = request.env['omniauth.auth']
    @user = User.find_by_password_digest(auth_hash[:uid])
    if @user and @user.enabled
      sign_in @user
      redirect_back_or root_url
    else
      flash[:error] = 'Sign-in failed.'
      redirect_to signin_url
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end

  ##
  # Responds to GET /signin
  #
  def new
  end

end
