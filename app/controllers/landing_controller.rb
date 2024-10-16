class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  #
  def index
    authorize(:landing)
    @gateway_item_count = Rails.cache.fetch('gateway.item_count',
                                            expires_in: 12.hours) do
      begin
        GatewayClient.instance.num_items
      rescue
        # The gateway is probably down. This is a problem that is better dealt
        # with elsewhere; failing here should not fail the request.
        nil
      end
    end
  end

end
