##
# Client for the Metadata Gateway.
#
class GatewayClient

  ITEM_COUNT_CACHE_KEY = "gateway.items.count"
  ITEM_COUNT_CACHE_TTL = 12.hours

  include Singleton

  ##
  # @return [Integer] Total number of items available.
  #
  def num_items
    Rails.cache.fetch(ITEM_COUNT_CACHE_KEY,
                      expires_in: ITEM_COUNT_CACHE_TTL) do
      config   = ::Configuration.instance
      url      = config.metadata_gateway_url.chomp('/') + '/items.json'
      response = http_client.get(url)
      struct   = JSON.parse(response.body)
      struct['numResults']
    end
  end

  ## 
  # @return [Integer] Total number of items in Digital Special Collections.
  # 
  def special_collections_num_items
    config = ::Configuration.instance
    url = config.metadata_gateway_url.chomp('/') + '/items.json?fq[]=local_facet_service:Digital Special Collections'
    response = http_client.get(url)
    struct = JSON.parse(response.body)
    struct['numResults']
  end

  private

  ##
  # @return [HTTPClient]
  #
  def http_client
    unless @client
      @client = HTTPClient.new do
        self.ssl_config.cert_store.set_default_paths
        #self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.receive_timeout        = 10000
      end
    end
    @client
  end

end