class BinariesController < WebsiteController

  include ActionController::Streaming

  before_action :check_storage, :load_binary, :authorize_item

  ##
  # Retrieves a binary.
  #
  # Responds to GET /binaries/:id
  #
  def show
    pathname = @binary.absolute_local_pathname
    if File.exists?(pathname)
      if File.readable?(pathname)
        send_file(pathname)
      else
        raise IOError, 'File is not readable.'
      end
    else
      raise IOError, 'File does not exist.'
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
