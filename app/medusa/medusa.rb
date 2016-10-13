class Medusa

  @@client = nil

  ##
  # @return [HTTPClient] With auth credentials already set.
  #
  def self.client
    unless @@client
      config = Configuration.instance
      @@client = HTTPClient.new do
        self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.force_basic_auth = true
        self.receive_timeout = 10000
        uri = URI.parse(config.medusa_url)
        domain = uri.scheme + '://' + uri.host
        user = config.medusa_user
        secret = config.medusa_secret
        self.set_auth(domain, user, secret)
      end
    end
    @@client
  end

end
