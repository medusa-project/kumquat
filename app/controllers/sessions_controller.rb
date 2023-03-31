class SessionsController < WebsiteController

  # This is contained within omniauth.
  skip_before_action :verify_authenticity_token

  ##
  # Responds to POST /auth/:provider/callback
  #
  def create
    # Any NetID user is allowed to log in, but only users who are members of
    # one of the relevant Medusa AD groups is given a User instance. Everyone
    # else simply has their NetID stored in the session. This is part of the
    # temporary Restricted Access feature (DLD-337).
    #
    # We can access other information via auth_hash[:extra][:raw_info][key]
    # where key is one of the shibboleth* keys in shibboleth.yml
    # (which have to correspond to passed attributes).
    auth_hash = request.env['omniauth.auth']
    if auth_hash && auth_hash[:uid]
      username   = auth_hash[:uid].split('@').first
      user       = User.new(username: username)
      if user.medusa_user?
        return_url = clear_and_return_return_path(admin_root_path)
        user       = User.find_or_create_by!(username: username)
        user.update!(last_logged_in_at: Time.now)
        sign_in user
      else
        return_url = clear_and_return_return_path(root_path)
        sign_in username
      end
      redirect_to return_url, allow_other_host: true
    else
      redirect_to root_url
    end
  end

  def destroy
    sign_out
    return_url = params[:referer] || root_path
    redirect_to return_url, allow_other_host: true
  end

  ##
  # Responds to GET /signin
  #
  def new
    session[:referer] = request.env['HTTP_REFERER']
    if Rails.env.production? or Rails.env.demo?
      redirect_to(shibboleth_login_path(Kumquat::Application.shibboleth_host))
    else
      redirect_to('/auth/developer')
    end
  end

  protected

  def clear_and_return_return_path(fallback_url)
    return_url = session[:return_to] || session[:referer] || fallback_url
    session[:return_to] = session[:referer] = nil
    reset_session
    return_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end

end
