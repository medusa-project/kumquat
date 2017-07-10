class BinariesController < WebsiteController

  include ActionController::Streaming

  before_action :check_storage, :load_binary, :authorize_item

  ##
  # Retrieves a binary.
  #
  # Responds to GET /binaries/:id
  #
  def show
    send_file(@binary.absolute_local_pathname)
  end

  private

  def authorize_item
    item = @binary.item
    return unless authorize(item.collection)
    return unless authorize(item)
  end

  def check_storage
    if Option::string(Option::Key::SERVER_STATUS) == 'storage_offline'
      render text: Option::string(Option::Key::SERVER_STATUS_MESSAGE),
             status: :service_unavailable
    end
  end

  def load_binary
    @binary = Binary.find_by_cfs_file_uuid(params[:id])
    raise ActiveRecord::RecordNotFound unless @binary
  end

end
