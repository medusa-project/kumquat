class BinariesController < WebsiteController

  include ActionController::Streaming

  before_action :load_binary, :authorize_collection, :authorize_item, :authorize_binary

  rescue_from AuthorizationError, with: :rescue_unauthorized

  LOGGER = CustomLogger.new(BinariesController)

  ##
  # Creates a presigned URL for downloading the given [Binary], and redirects
  # to it via HTTP 307.
  #
  # Note that for XHR requests, this requires an appropriate CORS policy to be
  # set on the bucket.
  #
  # Responds to `GET /binaries/:id`
  #
  def object
    url = @binary.presigned_url(content_disposition: content_disposition)
    redirect_to url, status: :temporary_redirect, allow_other_host: true
  end

  ##
  # Returns a binary's JSON representation.
  #
  # Responds to `GET /binaries/:id``
  #
  def show
    render json: @binary.decorate
  end

  ##
  # Streams a binary's associated S3 object to the response entity. Ranged
  # requests are supported.
  #
  # Note that because the the client-server connection is blocked while the
  # download is in progress, other clients may experience delays in connecting,
  # depending on the worker pool size and how requests are dispatched to it.
  #
  # A `content-disposition` query argument is accepted only with a value of
  # `inline`. If this is not provided then the disposition will be
  # `attachment`.
  #
  # Responds to `GET /binaries/:id`
  #
  def stream
    s3_request = {
      bucket: MedusaS3Client::BUCKET,
      key: @binary.object_key
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

    LOGGER.debug('stream(): requesting %s', s3_request)

    aws_response = MedusaS3Client.instance.head_object(s3_request)

    response.status                         = status
    response.headers['Content-Type']        = @binary.media_type
    response.headers['Content-Disposition'] = (params[:'content-disposition'] == "inline") ? "inline" : content_disposition
    response.headers['Content-Length']      = aws_response.content_length.to_s
    response.headers['Last-Modified']       = aws_response.last_modified.utc.strftime('%a, %d %b %Y %T GMT')
    response.headers['Cache-Control']       = 'public, must-revalidate, max-age=0'
    response.headers['Accept-Ranges']       = 'bytes'
    if @binary.duration.present?
      response.headers['Content-Duration']   = @binary.duration
      response.headers['X-Content-Duration'] = @binary.duration
    end
    MedusaS3Client.instance.get_object(s3_request) do |chunk|
      response.stream.write chunk
    end
  rescue Aws::S3::Plugins::NonRetryableStreamingError,
    ActionController::Live::ClientDisconnected => e
    # These may be raised when the client closes the connection prematurely.
    # Rescue them or else Rails will log it at error level.
    LOGGER.debug('stream(): %s', e)
  rescue Aws::S3::Errors::Http416Error
    render plain: 'Range not satisfyable', status: :range_not_satisfiable
  rescue Aws::S3::Errors::NotFound
    render plain: 'Object does not exist in bucket', status: :not_found
  ensure
    response.stream.close
  end


  private

  def authorize_binary
    unless @binary.public? || current_user&.medusa_user?
      raise AuthorizationError, "Binary is not public"
    end
  end

  def authorize_collection
    item = @binary.item
    if item
      return unless authorize(item.collection)
    end
  end

  def authorize_item
    item = @binary.item
    if item
      return unless authorize(item)
    end
  end

  def content_disposition
    utf8_filename  = @binary.filename
    ascii_filename = utf8_filename.gsub(/[^[:ascii:]]*/, '')
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally.
    "attachment; filename=\"#{ascii_filename.gsub('"', "\"")}\"; "\
        "filename*=UTF-8''#{ERB::Util.url_encode(utf8_filename)}"
  end

  def load_binary
    @binary = Binary.find_by_medusa_uuid(params[:id] || params[:binary_id])
    raise ActiveRecord::RecordNotFound unless @binary
  end

  def rescue_unauthorized
    render plain: 'You are not authorized to access this binary.',
           status: :forbidden
  end

end
