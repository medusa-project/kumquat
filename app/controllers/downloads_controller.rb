class DownloadsController < ApplicationController

  LOGGER = CustomLogger.new(DownloadsController)

  layout 'download'

  before_action :set_download
  before_action :authorize_download

  ##
  # Responds to `GET /downloads/:download_key/file`
  #
  def file
    if @download.expired
      render plain: 'This download is expired.', status: :gone
      return
    elsif @download.filename.present?
      # Generate a pre-signed URL to redirect to.
      signer = Aws::S3::Presigner.new(client: KumquatS3Client.instance)
      url    = signer.presigned_url(:get_object,
                                    bucket:     KumquatS3Client::BUCKET,
                                    key:        @download.object_key,
                                    response_content_disposition: content_disposition(@download.filename),
                                    expires_in: 900)
      redirect_to url, status: :see_other, allow_other_host: true
    else
      LOGGER.error('file(): object does not exist for download key %s',
                   @download.key)
      render plain: "File does not exist for download #{@download.key}.",
             status: :not_found
    end
  end

  ##
  # Responds to `GET /downloads/:key`
  #
  def show
    if @download.expired
      render 'expired', status: :gone
    end
    # Public clients will generally be arriving at this route via an XHR
    # redirect from some other route. This header is needed because it's
    # probably the best way to get the ultimately-redirected-to URL in
    # JavaScript.
    response.header['X-Kumquat-Location'] = download_url(@download, format: :json)
  end


  private

  def authorize_download
    @download ? authorize(@download) : skip_authorization
  end

  def content_disposition(filename) # TODO: BinariesController has a similar method
    utf8_filename  = filename
    ascii_filename = utf8_filename.gsub(/[^[:ascii:]]*/, '')
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally.
    "attachment; filename=\"#{ascii_filename.gsub('"', "\"")}\"; "\
        "filename*=UTF-8''#{ERB::Util.url_encode(utf8_filename)}"
  end

  def set_download
    @download = Download.find_by_key(params[:key] || params[:download_key])
    raise ActiveRecord::RecordNotFound unless @download
  end

end
