class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Live
  include SessionsHelper

  LOGGER = CustomLogger.new(ApplicationController)

  # N.B.: these must be listed in order of most generic to most specific.
  rescue_from StandardError, with: :rescue_internal_server_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_invalid_auth_token
  rescue_from ActionController::InvalidCrossOriginRequest, with: :rescue_invalid_cross_origin_request
  rescue_from ActionController::UnknownFormat, with: :rescue_unknown_format
  rescue_from ActionDispatch::RemoteIp::IpSpoofAttackError, with: :rescue_ip_spoof
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :rescue_parse_error
  rescue_from ActionView::Template::Error, with: :rescue_template_error
  rescue_from ActiveRecord::RecordNotFound, with: :rescue_not_found
  rescue_from NotAuthorizedError, with: :rescue_unauthorized

  protected

  ##
  # @param entity [Class] Model or any other object to which access can be
  #               authorized.
  # @param policy_class [ApplicationPolicy] Alternative policy class to use.
  # @param policy_method [Symbol] Alternative policy method to use.
  # @raises [NotAuthorizedError]
  #
  def authorize(entity, policy_class: nil, policy_method: nil)
    class_name     = controller_path.split("/").map(&:singularize).map(&:camelize).join("::")
    policy_class ||= "#{class_name}Policy".constantize
    instance       = policy_class.new(request_context, entity)
    result         = instance.send(policy_method&.to_sym || "#{action_name}?".to_sym)
    raise NotAuthorizedError.new unless result
  end

  ##
  # @return [Set<HostGroup>] Set of {HostGroup}s associated with the request
  #         hostname/IP address.
  #
  def client_host_groups
    HostGroup.all_matching_hostname_or_ip(request.host, request.remote_ip)
  end

  ##
  # Logs the given error and sets the flash to it.
  #
  # @param e [Exception, String]
  #
  def handle_error(e)
    LOGGER.warn(e)
    response.headers['X-Kumquat-Result'] = 'error'
    flash['error'] = "#{e}"
  end

  ##
  # Normally the flash is discarded after being added to the response headers
  # (see {flash_in_response_headers}). Calling this method will save it,
  # enabling it to work with redirects. (Notably, it works different than
  # {flash#keep}.)
  #
  def keep_flash
    @keep_flash = true
  end

  def skip_authorization
    # not entirely sure why we need this method, but here it is anyway
  end

  ##
  # Sends an Enumerable object in chunks as an attachment.
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
  # Stores the flash message and type (`error` or `success`) in the response
  # headers, where they can be accessed by an XHR callback. Afterwards, the
  # "normal" flash is cleared, which prevents it from working with redirects.
  # To prevent this, a controller should call {keep_flash} before redirecting.
  #
  def flash_in_response_headers
    if request.xhr?
      response.headers['X-Kumquat-Message-Type'] = 'error' unless
          flash['error'].blank?
      response.headers['X-Kumquat-Message-Type'] = 'success' unless
          flash['success'].blank?
      response.headers['X-Kumquat-Message'] = flash['error'] unless
          flash['error'].blank?
      response.headers['X-Kumquat-Message'] = flash['success'] unless
          flash['success'].blank?
      flash.clear unless @keep_flash
    end
  end

  def rescue_internal_server_error(exception)
    @message = KumquatMailer.error_body(exception,
                                        url_path:  request.path,
                                        url_query: request.query_string,
                                        user:      current_user)
    Rails.logger.error(@message)

    unless Rails.env.development?
      KumquatMailer.error(@message).deliver_now
    end

    respond_to do |format|
      format.html do
        render "errors/internal_server_error",
               status: :internal_server_error,
               content_type: "text/html"
      end
      format.all do
        render plain: "500 Internal Server Error",
               status: :internal_server_error,
               content_type: "text/plain"
      end
    end
  end

  ##
  # @return [RequestContext]
  #
  def request_context
    begin
      hostname = Resolv.getname(request.remote_ip)
    rescue Resolv::ResolvError
      hostname = nil
    end
    RequestContext.new(client_ip:       request.remote_ip,
                       client_hostname: hostname,
                       user:            current_user)
  end

  ##
  # By default, Rails logs {ActionController::InvalidAuthenticityToken}s at
  # error level. This only bloats the logs, so we handle it differently.
  #
  def rescue_invalid_auth_token
    render plain: "Invalid authenticity token.", status: :forbidden
  end

  ##
  # By default, Rails logs {ActionController::InvalidCrossOriginRequest}s at
  # error level. This only bloats the logs, so we handle it differently.
  #
  def rescue_invalid_cross_origin_request
    render plain: "Invalid cross-origin request.", status: :bad_request
  end

  def rescue_ip_spoof
    render plain: 'Client IP mismatch.', status: :bad_request
  end

  def rescue_not_found
    message = 'This resource does not exist.'
    respond_to do |format|
      format.html do
        render 'errors/error', status: :not_found, locals: {
            status_code: 404,
            status_message: 'Not Found',
            message: message
        }
      end
      format.json do
        render 'errors/error', status: :not_found, locals: { message: message }
      end
      format.all do
        render plain: "404 Not Found", status: :not_found,
               content_type: "text/plain"
      end
    end
  end

  def rescue_parse_error
    render plain: 'Invalid request parameters.', status: :bad_request
  end

  def rescue_template_error(exception)
    # This is raised by stylesheet_link_tag() when the client IP does not match
    # the X-Forwarded-For header. We want to stop processing but not make it
    # to rescue_internal_server_error().
    if exception.message.start_with?('IP spoofing attack')
      render plain: '400 Bad Request', status: :bad_request
    else
      raise exception
    end
  end

  def rescue_unauthorized
    message = 'You are not authorized to access this page.'
    respond_to do |format|
      format.html do
        render 'errors/error', status: :forbidden, locals: {
          status_code:    403,
          status_message: 'Forbidden',
          message:        message
        }
      end
      format.json do
        render 'errors/error', status: :forbidden,
               locals: { message: message }
      end
      format.all do
        render plain:        "403 Forbidden",
               status:       :forbidden,
               content_type: "text/plain"
      end
    end
  end

  def rescue_unknown_format
    render plain: "Sorry, we aren't able to provide the requested format.",
           status: :unsupported_media_type
  end

end
