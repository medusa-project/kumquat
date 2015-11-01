module SessionsHelper

  def current_user=(user)
    @current_user = user
  end

  def current_user
    unless session[:user].nil?
      @current_user = User.find(session[:user])
    end
  end

  def current_user?(user)
    user == current_user
  end

  def sign_in(user)
    session[:user] = user.id
    self.current_user = user
  end

  def sign_out
    session[:user] = nil
    self.current_user = nil
  end

  def signed_in?
    !current_user.nil?
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    session[:return_to] = request.url if request.get?
  end

end
