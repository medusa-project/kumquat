module SessionsHelper

  def current_user=(user)
    @current_user = user
  end

  def current_user
    unless @current_user
      if session[:user].present?
        @current_user = User.find(session[:user])
      elsif session[:netid].present?
        @current_user = User.new(username: session[:netid])
      end
    end
    @current_user
  end

  def current_user?(user)
    user == current_user
  end

  def sign_in(user)
    if user.kind_of?(User)
      session[:user] = user.id
      self.current_user = user
    else
      session[:netid] = user
    end
  end

  def sign_out
    session[:user] = nil
    session[:netid] = nil
    self.current_user = nil
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    session[:return_to] = request.url if request.get?
  end

end
