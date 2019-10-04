class LandingController < WebsiteController

  ##
  # Responds to GET /
  #
  def index
    @gateway_item_count = CacheItem.get_or(CacheItem::Key::GATEWAY_ITEM_COUNT, 24 * 60 * 60) do
      url = ::Configuration.instance.metadata_gateway_url.chomp('/') + '/items.json'
      response = GatewayClient.new.get(url)
      struct = JSON.parse(response.body)
      struct['numResults']
    end
  end

end
