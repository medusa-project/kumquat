class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    @gateway_item_count = Rails.cache.fetch('gateway.item_count',
                                            expires_in: 12.hours) do
      url = ::Configuration.instance.metadata_gateway_url.chomp('/') + '/items.json'
      response = GatewayClient.new.get(url)
      struct = JSON.parse(response.body)
      struct['numResults']
    end
  end

end
