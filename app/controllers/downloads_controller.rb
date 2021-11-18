class DownloadsController < ApplicationController

  LOGGER = CustomLogger.new(DownloadsController)

  layout 'download'

  rescue_from AuthorizationError, with: :rescue_unauthorized

  ##
  # Responds to `GET /downloads/:download_key/file`
  #
  def file
    download = Download.find_by_key(params[:download_key])
    raise ActiveRecord::RecordNotFound unless download

    if download.expired
      render plain: 'This download is expired.', status: :gone
    elsif download.ip_address != request.remote_ip
      raise AuthorizationError
    elsif download.filename.present?
      # Generate a pre-signed URL to redirect to.
      signer = Aws::S3::Presigner.new(client: KumquatS3Client.instance)
      url    = signer.presigned_url(:get_object,
                                    bucket:     KumquatS3Client::BUCKET,
                                    key:        download.object_key,
                                    response_content_disposition: content_disposition(download.filename),
                                    expires_in: 900)
      redirect_to url, status: :see_other
    else
      LOGGER.error('file(): object does not exist for download key %s',
                   download.key)
      render plain: "File does not exist for download #{download.key}.",
             status: :not_found
    end
  end

  ##
  # Responds to `GET /downloads/:key`
  #
  def show
    @download = Download.find_by_key(params[:key])
    raise ActiveRecord::RecordNotFound unless @download

    if @download.expired
      render 'expired', status: :gone
    end
  end


  private

  def content_disposition(filename) # TODO: BinariesController has a similar method
    utf8_filename  = filename
    ascii_filename = utf8_filename.gsub(/[^[:ascii:]]*/, '')
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally.
    "attachment; filename=\"#{ascii_filename.gsub('"', "\"")}\"; "\
        "filename*=UTF-8''#{ERB::Util.url_encode(utf8_filename)}"
  end

  def rescue_unauthorized
    render plain:  "You are not authorized to access this download.",
           status: :forbidden
  end

end
