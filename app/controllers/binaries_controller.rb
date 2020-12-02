class BinariesController < WebsiteController

  include ActionController::Streaming

  before_action :load_binary, :authorize_collection, :authorize_item, :authorize_binary

  rescue_from AuthorizationError, with: :rescue_unauthorized

  ##
  # Retrieves a binary.
  #
  # Responds to GET /binaries/:id
  #
  def show
    if request.format == 'json'
      render json: @binary.decorate
    else
      send_binary(@binary)
    end
  end

  private

  def authorize_binary
    unless @binary.public || current_user&.medusa_user?
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

  def load_binary
    @binary = Binary.find_by_medusa_uuid(params[:id])
    raise ActiveRecord::RecordNotFound unless @binary
  end

  def rescue_unauthorized
    render plain: 'You are not authorized to access this binary.',
           status: :forbidden
  end

end
