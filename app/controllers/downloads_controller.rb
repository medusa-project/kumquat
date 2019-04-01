class DownloadsController < ApplicationController

  LOGGER = CustomLogger.new(DownloadsController)

  layout 'download'

  ##
  # Responds to GET /downloads/:download_key/file
  #
  def file
    download = Download.find_by_key(params[:download_key])
    raise ActiveRecord::RecordNotFound unless download

    if download.expired
      render plain: 'This download is expired.', status: :gone
    elsif File.exists?(download.pathname)
      send_file(download.pathname)
    else
      LOGGER.error('file(): download %s: file does not exist: %s',
                     download.id, download.pathname)
      render plain: "File does not exist for download #{download.key}.",
             status: :not_found
    end
  end

  ##
  # Responds to GET /downloads/:key
  #
  def show
    @download = Download.find_by_key(params[:key])
    raise ActiveRecord::RecordNotFound unless @download

    if @download.expired
      render 'expired', status: :gone
    end
  end

end
