class SessionsController < WebsiteController

  # This is contained within omniauth.
  skip_before_action :verify_authenticity_token

  ##
  # Responds to POST /auth/:provider/callback
  #
  def create
    auth_hash = request.env['omniauth.auth']
    if auth_hash and auth_hash[:uid]
      username = auth_hash[:uid].split('@').first
      user = User.find_by_username(username)
      if user and user.enabled
        return_url = clear_and_return_return_path
        sign_in user
        # We can access other information via auth_hash[:extra][:raw_info][key]
        # where key is one of the shibboleth* keys in shibboleth.yml
        # (which have to correspond to passed attributes).
        redirect_to return_url
        return
      end
    end
    flash['error'] = 'Sign-in failed.'
    redirect_to root_url
  end

  def destroy
    sign_out
    return_url = params[:referer] || root_path
    redirect_to return_url
  end

  ##
  # Responds to GET /signin
  #
  def new
    session[:referer] = request.env['HTTP_REFERER']
    if Rails.env.production?
      redirect_to(shibboleth_login_path(PearTree::Application.shibboleth_host))
    else
      redirect_to('/auth/developer')
    end
  end

  protected

  def clear_and_return_return_path
    return_url = session[:return_to] || session[:referer] || admin_root_path
    session[:return_to] = session[:referer] = nil
    reset_session
    return_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end

end
