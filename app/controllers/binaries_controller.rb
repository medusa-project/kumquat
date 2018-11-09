class BinariesController < WebsiteController

  include ActionController::Streaming

  before_action :check_storage, :load_binary, :authorize_item

  ##
  # Retrieves a binary.
  #
  # Responds to GET /binaries/:id
  #
  def show
    if request.format == 'json'
      render json: @binary.decorate
    else
      file_begin = 0
      file_size = @binary.byte_size
      file_end = file_size - 1

      if !request.headers['Range']
        status_code = '200 OK'
      else
        status_code = '206 Partial Content'
        match = request.headers['Range'].match(/bytes=(\d+)-(\d*)/)
        if match
          file_begin = match[1]
          file_end = match[2] if match[2] && match[2].present?
        end
        response.header['Content-Range'] = sprintf('bytes %d-%d/%d',
                                                   file_begin, file_end, file_size)
      end
      response.header['Content-Length'] = (file_end.to_i - file_begin.to_i + 1).to_s
      response.header['Last-Modified'] = @binary.updated_at.to_s
      response.header['Cache-Control'] = 'public, must-revalidate, max-age=0'
      response.header['Pragma'] = 'no-cache'
      response.header['Accept-Ranges'] =  'bytes'
      response.header['Content-Transfer-Encoding'] = 'binary'
      send_file(@binary.absolute_local_pathname,
                filename: File.basename(@binary.repository_relative_pathname),
                type: @binary.media_type,
                disposition: 'attachment',
                status: status_code,
                stream: 'true',
                buffer_size: 8192)
    end
  end

  private

  def authorize_item
    item = @binary.item
    return unless authorize(item.collection)
    return unless authorize(item)
  end

  def check_storage
    if Option::string(Option::Keys::SERVER_STATUS) == 'storage_offline'
      render plain: Option::string(Option::Keys::SERVER_STATUS_MESSAGE),
             status: :service_unavailable
    end
  end

  def load_binary
    @binary = Binary.find_by_cfs_file_uuid(params[:id])
    raise ActiveRecord::RecordNotFound unless @binary
  end

end
