class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Live
  include SessionsHelper

  before_action :setup
  after_action :flash_in_response_headers, :log_execution_time

  def setup
    @start_time = Time.now
  end

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_url, notice: 'Please log in.'
    end
  end

  protected

  ##
  # Logs the given error and sets the flash to it.
  #
  # @param e [Exception, String]
  #
  def handle_error(e)
    CustomLogger.instance.warn(e)
    response.headers['X-Kumquat-Result'] = 'error'
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
    roles = Set.new
    roles += current_user.roles if current_user
    roles += Role.all_matching_hostname_or_ip(request.host, request.remote_ip)
    roles
  end

  ##
  # Streams an S3 object, represented by a Binary, to the response entity.
  # Ranged requests are supported.
  #
  # @param binary [Binary]
  #
  def send_binary(binary)
    s3_request = {
        bucket: ::Configuration.instance.repository_s3_bucket,
        key: binary.object_key
    }

    file_begin     = 0
    file_size      = @binary.byte_size
    file_end       = file_size - 1
    content_length = file_end.to_i - file_begin.to_i + 1

    if !request.headers['Range']
      status_code = '200 OK'
    else
      status_code = '206 Partial Content'
      match = request.headers['Range'].match(/bytes=(\d+)-(\d*)/)
      if match
        file_begin = match[1].to_i
        file_end   = match[2].to_i if match[2]&.present?
      end
      range = sprintf('bytes %d-%d/%d', file_begin, file_end, file_size)
      response.headers['Content-Range'] = s3_request[:range] = range
    end

    response.status                               = status_code
    response.headers['Content-Type']              = binary.media_type
    response.headers['Content-Disposition']       = "attachment; filename=#{binary.filename}"
    response.headers['Content-Length']            = content_length.to_s
    response.headers['Last-Modified']             = @binary.updated_at.to_s
    response.headers['Cache-Control']             = 'public, must-revalidate, max-age=0'
    response.headers['Accept-Ranges']             = 'bytes'
    response.headers['Content-Transfer-Encoding'] = 'binary'
    if binary.duration.present?
      response.headers['Content-Duration']        = binary.duration
      response.headers['X-Content-Duration']      = binary.duration
    end

    Aws::S3::Client.new.get_object(s3_request) do |chunk|
      response.stream.write chunk
    end
  ensure
    response.stream.close
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
    CustomLogger.instance.info("#{controller_name.capitalize}Controller.#{action_name}(): "\
        "executed in #{(Time.now - @start_time) * 1000}ms")
  end

end
