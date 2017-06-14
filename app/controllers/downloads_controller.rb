class DownloadsController < ApplicationController

  layout 'download'

  ##
  # Responds to GET /downloads/:download_key/file
  #
  def file
    download = Download.find_by_key(params[:download_key])
    raise ActiveRecord::RecordNotFound unless download

    if File.exists?(download.pathname)
      send_file(download.pathname)
    else
      CustomLogger.instance.error("DownloadsController.file(): "\
          "Download #{download.id}: "\
          "file does not exist: #{download.pathname}")
      render text: "File does not exist for download #{download.key}.",
             status: :not_found
    end
  end

  ##
  # Responds to GET /downloads/:key
  #
  def show
    @download = Download.find_by_key(params[:key])
    raise ActiveRecord::RecordNotFound unless @download

    #@download = Download.new(percent_complete: 0.45234, key: 'asdfasdf')
    #render :ready

    render @download.ready? ? :ready : :preparing
  end

end
