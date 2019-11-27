##
# Client for the Metadata Gateway.
#
class GatewayClient

  include Singleton

  ##
  # @return [Integer] Total number of items available.
  #
  def num_items
    url = ::Configuration.instance.metadata_gateway_url.chomp('/') + '/items.json'
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