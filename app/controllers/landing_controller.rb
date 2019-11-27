class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    @gateway_item_count = Rails.cache.fetch('gateway.item_count',
                                            expires_in: 12.hours) do
      GatewayClient.instance.num_items
    end
  end

end
