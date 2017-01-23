##
# Client for the [Medusa Downloader]
# (https://github.com/medusa-project/medusa-downloader).
#
# Originally based on:
# https://github.com/medusa-project/databank/blob/09165ab803d739d7ec2b52f498ba68f35601fb5e/app/models/downloader_client.rb
#
class DownloaderClient

  include ActiveModel::Conversion
  include ActiveModel::Naming

  BATCH_SIZE = 200

  def initialize
    config = ::Configuration.instance
    @url = config.downloader[:url]
    @user = config.downloader[:user]
    @password = config.downloader[:password]
  end

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

    targets = []
    items.each do |item|
      access_bs = item.access_master_bytestream
      pres_bs = item.preservation_master_bytestream
      if access_bs or pres_bs
        # Add a containing directory for the item.
        item_zip_path = '/' + File.basename((access_bs&.repository_relative_pathname ||
            pres_bs&.repository_relative_pathname), '.*')
        if access_bs
          targets.push({
              'type': 'file',
              'path': access_bs.repository_relative_pathname,
              'zip_path': item_zip_path + '/access'
          })
        end
        if pres_bs
          targets.push({
              'type': 'file',
              'path': pres_bs.repository_relative_pathname,
              'zip_path': item_zip_path + '/preservation'
          })
        end
      else
        CustomLogger.instance.
            info("Item has no bytestreams: #{item.repository_id}")
      end
    end

    if targets.count == 0
      raise ArgumentError, 'No files to download.'
    end

    request_hash = {}
    request_hash['root'] = 'medusa'
    request_hash['zip_name'] = "#{zip_name.chomp('.zip')}"
    request_hash['targets'] = targets

    medusa_request_json = request_hash.to_json

    url = "#{@url}/downloads/create"

    client = Curl::Easy.new(url)
    client.http_auth_types = :digest
    client.username = @user
    client.password = @password
    client.post_body = medusa_request_json
    client.post
    client.headers = { 'Content-Type' => 'application/json' }
    client.perform
    response_hash = JSON.parse(client.body_str)
    unless response_hash.has_key?('download_url')
      raise IOError, response_hash['error']
    end
    response_hash['download_url']
  end

end