##
# Client for downloading item content via the
# [Medusa Downloader](https://github.com/medusa-project/medusa-downloader).
#
class DownloaderClient

  BATCH_SIZE = 200

  ##
  # @param items [Enumerable<Item>]
  # @param zip_name [String]
  # @param package_profile [PackageProfile] Determines the directory layout of
  #                                         the items within the zip file.
  #                                         Only
  #                                         PackageProfile::FREE_FORM_PROFILE
  #                                         is treated any differently.
  # @return [String] Download URL to redirect to.
  # @raises [ArgumentError] If illegal arguments have been supplied.
  # @raises [IOError] If there is an error communicating with the downloader.
  #
  def download_url(items, zip_name, package_profile = nil)
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
        targets.push({
                         'type': 'file',
                         'path': binary.repository_relative_pathname,
                         'zip_path': zip_dirname(binary, package_profile)
                     })
      end
    end

    if targets.count < 1
      raise ArgumentError, 'No files to download.'
    end

    config = ::Configuration.instance

    url = "#{config.downloader[:url]}/downloads/create"
    client = Curl::Easy.new(url)
    client.http_auth_types = :digest
    client.username = config.downloader[:user]
    client.password = config.downloader[:password]
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
      raise IOError, response_hash['error']
    end
    response_hash['download_url']
  end

  private

  ##
  # @param binary [Binary]
  # @param package_profile [PackageProfile]
  # @return [String] Path of the given binary within the zip file.
  #
  def zip_dirname(binary, package_profile)
    case package_profile
      when PackageProfile::FREE_FORM_PROFILE
        # Preserve the binary's pathname starting at its collection's effective
        # root pathname.
        root = binary.item.collection.effective_medusa_cfs_directory.
            repository_relative_pathname
        return File.dirname(binary.repository_relative_pathname.gsub(/^#{root}/, ''))
      else
        item_dirname = '/' + (binary.item.bib_id || binary.item.repository_id)
        type_path = (binary.master_type == Binary::MasterType::PRESERVATION) ?
            '/preservation' : '/access'
        category_path = binary.media_category.present? ?
            "/#{binary.human_readable_media_category.downcase}" : ''
        return item_dirname + type_path + category_path
    end
  end

end