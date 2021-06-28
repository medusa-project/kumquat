class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Live
  include SessionsHelper

  # N.B.: these must be listed in order of most generic to most specific.
  rescue_from StandardError, with: :rescue_internal_server_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_invalid_auth_token
  rescue_from ActionController::InvalidCrossOriginRequest, with: :rescue_invalid_cross_origin_request
  rescue_from ActionController::UnknownFormat, with: :rescue_unknown_format
  rescue_from ActionDispatch::RemoteIp::IpSpoofAttackError, with: :rescue_ip_spoof
  rescue_from ActiveRecord::RecordNotFound, with: :rescue_not_found

  before_action :setup
  after_action :flash_in_response_headers, :log_execution_time

  LOGGER = CustomLogger.new(ApplicationController)

  def setup
    @start_time = Time.now
  end


  protected

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

  ##
  # @return [Set<HostGroup>] Set of {HostGroup}s associated with the request
  #         hostname/IP address.
  #
  def client_host_groups
    HostGroup.all_matching_hostname_or_ip(request.host, request.remote_ip)
  end

  ##
  # Streams a {Binary}'s associated S3 object to the response entity.
  # Ranged requests are supported.
  #
  # @param binary [Binary]
  #
  def send_binary(binary)
    s3_request = {
        bucket: MedusaS3Client::BUCKET,
        key: binary.object_key
    }

    if !request.headers['Range']
      status = '200 OK'
    else
      status  = '206 Partial Content'
      start_offset = 0
      length       = @binary.byte_size
      end_offset   = length - 1
      match        = request.headers['Range'].match(/bytes=(\d+)-(\d*)/)
      if match
        start_offset = match[1].to_i
        end_offset   = match[2].to_i if match[2]&.present?
      end
      response.headers['Content-Range'] = sprintf('bytes %d-%d/%d',
                                                  start_offset, end_offset, length)
      s3_request[:range]                = sprintf('bytes=%d-%d',
                                                  start_offset, end_offset)
    end

    LOGGER.debug('send_binary(): requesting %s', s3_request)

    aws_response = MedusaS3Client.instance.head_object(s3_request)

    response.status                         = status
    response.headers['Content-Type']        = binary.media_type
    response.headers['Content-Disposition'] = "attachment; filename=#{binary.filename}"
    response.headers['Content-Length']      = aws_response.content_length.to_s
    response.headers['Last-Modified']       = aws_response.last_modified.utc.strftime('%a, %d %b %Y %T GMT')
    response.headers['Cache-Control']       = 'public, must-revalidate, max-age=0'
    response.headers['Accept-Ranges']       = 'bytes'
    if binary.duration.present?
      response.headers['Content-Duration']   = binary.duration
      response.headers['X-Content-Duration'] = binary.duration
    end
    MedusaS3Client.instance.get_object(s3_request) do |chunk|
      response.stream.write chunk
    end
  rescue ActionController::Live::ClientDisconnected => e
    # Rescue this or else Rails will log it at error level.
    LOGGER.debug('send_binary(): %s', e)
  rescue Aws::S3::Errors::NotFound
    render plain: 'Object does not exist in bucket', status: :not_found
  ensure
    response.stream.close
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

  def log_execution_time
    LOGGER.info('%sController.%s(): executed in %d ms',
                controller_name.capitalize,
                action_name,
                (Time.now - @start_time) * 1000)
  end

  def rescue_internal_server_error(exception)
    @message = KumquatMailer.error_body(exception,
                                        url:       request.url,
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
  # By default, Rails logs {ActionController::InvalidAuthenticityToken}s at
  # error level. This only bloats the logs, so we handle it differently.
  #
  def rescue_invalid_auth_token
    render plain: "Invalid authenticity token.", status: :bad_request
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

  def rescue_unknown_format
    render plain: "Sorry, we aren't able to provide the requested format.",
           status: :unsupported_media_type
  end

end
