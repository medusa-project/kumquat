##
# Client for downloading item content via the
# [Medusa Downloader](https://github.com/medusa-project/medusa-downloader).
#
class MedusaDownloaderClient

  BATCH_SIZE = 200

  ##
  # @param items [Enumerable<Item>]
  # @param zip_name [String]
  # @return [String] Download URL to redirect to.
  # @raises [ArgumentError] If illegal arguments have been supplied.
  # @raises [IOError] If there is an error communicating with the downloader.
  #
  def download_url(items, zip_name)
    if !items.respond_to?(:each)
      raise ArgumentError, 'Invalid items argument.'
    elsif items.length < 1
      raise ArgumentError, 'No items provided.'
    end

    # Compile this list of items to include in the file. The directory layout
    # within the file will differ depending on the given package profile.
    targets = []
    items.each do |item|
      item.binaries.each do |binary|
        zip_dirname = zip_dirname(binary)
        if zip_dirname
          targets.push({
                           'type': 'file',
                           'path': binary.object_key,
                           'zip_path': zip_dirname
                       })
        end
      end
    end

    if targets.count < 1
      raise ArgumentError, 'No files to download.'
    end

    config = ::Configuration.instance

    url = "#{config.downloader_url}/downloads/create"
    client = Curl::Easy.new(url)
    client.http_auth_types = :digest
    client.username = config.downloader_user
    client.password = config.downloader_password
    client.post_body = {
        'root': 'medusa',
        'zip_name': "#{zip_name.chomp('.zip')}",
        'targets': targets
    }.to_json
    client.post
    client.headers = { 'Content-Type': 'application/json' }
    client.perform
    response_hash = JSON.parse(client.body_str)
    unless response_hash.has_key?('download_url')
      CustomLogger.instance.error("MedusaDownloaderClient.download_url(): "\
          "received HTTP #{client.status}: "\
          "#{client.body_str}")
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
    config = ::Configuration.instance

    url = config.downloader_url
    client = Curl::Easy.new(url)
    client.http_auth_types = :digest
    client.username = config.downloader_user
    client.password = config.downloader_password
    client.head
    client.perform
    raise IOError, client.status if client.response_code != 200
  end

  private

  ##
  # @param binary [Binary]
  # @return [String] Path of the given binary within the zip file.
  #
  def zip_dirname(binary)
    root = '/' + binary.item.collection.effective_medusa_cfs_directory&.pathname
    root ? File.dirname('/' + binary.object_key.gsub(/^#{root}/, '')) : nil
  end

end