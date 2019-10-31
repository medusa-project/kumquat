##
# Client for the Metadata Gateway.
#
class GatewayClient

  @@client = nil

  ##
  # @return [HTTPClient] With auth credentials already set.
  #
  def self.http_client
    unless @@client
      @@client = HTTPClient.new do
        self.ssl_config.cert_store.set_default_paths
        self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.receive_timeout        = 10000
      end
    end
    @@client
  end

  def get(url, *args)
    args = merge_args(args)
    self.class.http_client.get(url, args)
  end

  def head(url, *args)
    args = merge_args(args)
    self.class.http_client.head(url, args)
  end

  private

  def merge_args(args)
    extra_args = { follow_redirect: true }
    if args[0].kind_of?(Hash)
      args[0] = extra_args.merge(args[0])
    else
      return extra_args
    end
    args
  end

end