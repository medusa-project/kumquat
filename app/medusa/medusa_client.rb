##
# High-level client for the Medusa Collection Registry.
#
class MedusaClient

  include Singleton

  ##
  # @param uuid [String]
  # @return [Class]
  #
  def class_of_uuid(uuid)
    url = Configuration.instance.medusa_url.chomp('/') + '/uuids/' +
        uuid.to_s.strip + '.json'
    begin
      response = get(url, follow_redirect: false)
      location = response.header['location'].first
      if location
        if location.include?('file_groups/')
          return MedusaFileGroup
        elsif location.include?('/cfs_directories/')
          return MedusaCfsDirectory
        elsif location.include?('/cfs_files/')
          return MedusaCfsFile
        end
      end
    rescue HTTPClient::BadResponseError
      # no-op
    end
    nil
  end

  def get(url, follow_redirect: true)
    http_client.get(url, follow_redirect: follow_redirect)
  end

  def get_uuid(url, follow_redirect: true)
    get(url_for_uuid(url), follow_redirect: follow_redirect)
  end

  def head(url, follow_redirect: true)
    http_client.head(url, follow_redirect: follow_redirect)
  end

  private

  ##
  # @return [HTTPClient] With auth credentials already set.
  #
  def http_client
    unless @client
      @client = HTTPClient.new do
        config = Configuration.instance
        # use the OS cert store
        self.ssl_config.cert_store.set_default_paths
        #self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.force_basic_auth = true
        self.receive_timeout = 10000
        uri     = URI.parse(config.medusa_url)
        domain  = uri.scheme + '://' + uri.host
        domain += ":#{uri.port}" unless [80, 443].include?(uri.port)
        user    = config.medusa_user
        secret  = config.medusa_secret
        self.set_auth(domain, user, secret)
      end
    end
    @client
  end

  ##
  # @param uuid [String]
  # @return [String, nil] URI of the corresponding Medusa resource.
  #
  def url_for_uuid(uuid)
    sprintf('%s/uuids/%s.json', Configuration.instance.medusa_url.chomp('/'),
            uuid)
  end

end