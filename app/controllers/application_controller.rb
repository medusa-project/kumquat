class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include SessionsHelper

  before_action :setup
  after_action :flash_in_response_headers

  def setup
  end

  def admin_user
    unless current_user.is_admin?
      flash['error'] = 'Access denied.'
      store_location
      redirect_to root_url
    end
  end

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_url, notice: 'Please sign in.'
    end
  end

  protected

  ##
  # Logs the given error and sets the flash to it.
  #
  # @param e [Exception, String]
  #
  def handle_error(e)
    Rails.logger.warn(e)
    flash['error'] = "#{e}"
  end

  ##
  # Normally the flash is discarded after being added to the response headers
  # (see flash_in_response_headers). Calling this method will save it, enabling
  # it to work with redirects. (Notably, it works different than flash.keep.)
  #
  def keep_flash
    @keep_flash = true
  end

  ##
  # @return [Set<Role>] Set of Roles associated with the current user, if
  #                     available, or the request hostname/IP address otherwise.
  #
  def request_roles
    return Set.new(current_user.roles) if current_user
    Role.all_matching_hostname_or_ip(request.host, request.remote_ip)
  end

  ##
  # Sends an Enumerable object in chunks as an attachment. Streaming requires
  # a web server capable of it (not WEBrick).
  #
  def stream(enumerable, filename)
    headers['X-Accel-Buffering'] = 'no'
    headers['Cache-Control'] ||= 'no-cache'
    headers.delete('Content-Length')
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    self.response_body = enumerable
  end

  private

  @keep_flash = false

  ##
  # Stores the flash message and type ('error' or 'success') in the response
  # headers, where they can be accessed by an ajax callback. Afterwards, the
  # "normal" flash is cleared, which prevents it from working with redirects.
  # To prevent this, a controller should call keep_flash before redirecting.
  #
  def flash_in_response_headers
    if request.xhr?
      response.headers['X-PearTree-Message-Type'] = 'error' unless
          flash['error'].blank?
      response.headers['X-PearTree-Message-Type'] = 'success' unless
          flash['success'].blank?
      response.headers['X-PearTree-Message'] = flash['error'] unless
          flash['error'].blank?
      response.headers['X-PearTree-Message'] = flash['success'] unless
          flash['success'].blank?
      flash.clear unless @keep_flash
    end
  end

end
