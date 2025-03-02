##
# Client for downloading item content via the
# [Medusa Downloader](https://github.com/medusa-project/medusa-downloader).
#
class MedusaDownloaderClient

  LOGGER = CustomLogger.new(MedusaDownloaderClient)

  CREATE_DOWNLOAD_PATH = '/downloads/create'

  # Target batch byte size when the total download size is known.
  TARGET_BATCH_BYTE_SIZE = 2**30 # 1 GB

  # Target number of items per batch when their total byte size is not known.
  TARGET_BATCH_SIZE = 200

  ##
  # Sends a request to the Downloader to generate a zip file for the given
  # arguments, and returns its URL.
  #
  # @param items [ActiveRecord::Relation<Item>]
  # @param zip_name [String] Desired name of the zip file, with or without
  #                          `.zip` suffix.
  # @param include_private_binaries [Boolean]
  # @return [String] Download URL to which clients can be redirected.
  # @raises [ArgumentError] If illegal arguments have been supplied.
  # @raises [IOError] If there is an error communicating with the Downloader.
  #
  def download_url(items:, zip_name:, include_private_binaries: false)
    if !items.respond_to?(:each)
      raise ArgumentError, 'Invalid items argument.'
    elsif items.count < 1
      raise ArgumentError, 'No items provided.'
    end

    # Compile the list of items to include in the file.
    targets = targets_for(items, include_private_binaries: include_private_binaries)
    if targets.length < 1
      raise ArgumentError, 'No files to download.'
    end

    # Prepare the initial request.
    config  = ::Configuration.instance
    url     = "#{config.downloader_url}/#{CREATE_DOWNLOAD_PATH}"
    headers = { 'Content-Type': 'application/json' }
    body    = JSON.generate(
        root:     'medusa',
        zip_name: "#{zip_name.chomp('.zip')}",
        targets:  targets)

    LOGGER.debug('download_url(): requesting %s', body)
    response = client.post(url, body, headers)

    # Ideally this would be 200, but HTTPClient's digest auth doesn't seem to
    # work as of 2.8.3, so it's more likely 401 so we'll have to do the digest
    # auth flow manually.
    if response.status == 401
      headers['Authorization'] =
          digest_auth_header(response.headers['WWW-Authenticate'])

      LOGGER.debug('download_url(): retrying %s', body)
      response = client.post(url, body, headers)
    end

    response_hash = JSON.parse(response.body)
    if response.status > 299
      LOGGER.error('download_url(): received HTTP %d: %s',
                   response.status, response.body)
      raise IOError, response_hash['error']
    end
    response_hash['download_url']
  end

  ##
  # Issues an HTTP HEAD request to check whether the server is up.
  #
  # @raises [IOError] If the server does not respond as expected.
  #
  def head
    config   = ::Configuration.instance
    response = client.head(config.downloader_url)
    raise IOError, response.status if response.status != 200
  end

  # helper method that is public calls on targets_for pvt method so ItemsController can have access to the method
  def process_targets(items, include_private_binaries: false)
    targets_for(items, include_private_binaries: include_private_binaries)
  end

  private

  def client
    unless @client
      config = ::Configuration.instance
      url    = config.downloader_url
      @client = HTTPClient.new do
        self.ssl_config.cert_store.set_default_paths
        self.receive_timeout = 10000
        uri     = URI.parse(url)
        domain  = uri.scheme + '://' + uri.host
        domain += ":#{uri.port}" unless [80, 443].include?(uri.port)
        user    = config.downloader_user
        secret  = config.downloader_password
        self.set_auth(domain, user, secret)
      end
    end
    @client
  end

  ##
  # @param www_authenticate_header [String] `WWW-Authenticate` response header
  #                                         value.
  # @return [String] Value to use in an `Authorization` header.
  #
  def digest_auth_header(www_authenticate_header)
    config                = ::Configuration.instance
    auth_info             = parse_auth_header(www_authenticate_header)
    auth_info['username'] = config.downloader_user
    auth_info['uri']      = CREATE_DOWNLOAD_PATH
    auth_info['nc']       = '00000001'
    auth_info['cnonce']   = SecureRandom.hex

    ha1 = Digest('MD5').hexdigest(sprintf('%s:%s:%s',
                                          config.downloader_user,
                                          auth_info['realm'],
                                          config.downloader_password))
    ha2 = Digest('MD5').hexdigest("POST:#{CREATE_DOWNLOAD_PATH}")
    auth_info['response'] = Digest('MD5').hexdigest(sprintf('%s:%s:%s:%s:%s:%s',
                                                            ha1,
                                                            auth_info['nonce'],
                                                            auth_info['nc'],
                                                            auth_info['cnonce'],
                                                            auth_info['qop'],
                                                            ha2))
    "Digest #{auth_info.map{ |k,v| "#{k}=\"#{v}\"" }.join(', ')}"
  end

  ##
  # @param header [String]
  # @return [Hash]
  #
  def parse_auth_header(header)
    auth_info = {}
    matches = header.scan(/([a-zA-Z]+)="([^"]+)",?/)
    matches.each do |match|
      auth_info[match[0]] = match[1]
    end
    auth_info
  end

  ##
  # @param items [ActiveRecord::Relation<Item>]
  # @param include_private_binaries [Boolean]
  # @return [Array<Hash>]
  #
  def targets_for(items, include_private_binaries: false)
    targets = []
    Item.uncached do
      items.find_each do |item|
        if item.directory?
          dir = Medusa::Directory.with_uuid(item.repository_id)
          targets.push(type:      'directory',
                       path:      dir.relative_key,
                       zip_path:  dir.name,
                       recursive: true)
        elsif include_private_binaries || item.collection.publicize_binaries
          binaries = item.binaries
          # Exclude access masters (DLD-362)
          binaries = binaries.where('object_key NOT LIKE ?', '%/access/%') unless item.collection.free_form?
          binaries = binaries.where(public: true) unless include_private_binaries
          binaries.each do |binary|
            zip_dirname = zip_dirname(binary)
            if zip_dirname
              targets.push(type:     'file',
                           path:     binary.object_key,
                           zip_path: zip_dirname)
            end
          end
        end
      end
    end
    targets
  end

  ##
  # @param binary [Binary]
  # @return [String] Path of the given binary within the zip file.
  #
  def zip_dirname(binary)
    cfs_dir_path = binary.item.collection.effective_medusa_directory&.relative_key
    if cfs_dir_path
      root = '/' + cfs_dir_path
      return File.dirname('/' + binary.object_key.gsub(/^#{root}/, ''))
    end
    nil
  end

end