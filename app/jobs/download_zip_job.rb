class DownloadZipJob < Job

  queue_as :download

  ##
  # @param args [Array] Three-element array with array of Items at
  #                     position 0, zip name at position 1, and Download
  #                     instance at position 2.
  #
  def perform(*args)
    item_ids = args[0]
    zip_name = args[1]
    download = args[2]

    download.update(indeterminate: true)

    self.task&.update!(download: download,
                       status_text: "Requesting a #{item_ids.length}-item zip "\
                       "file from the Medusa Downloader")

    items = item_ids.map { |id| Item.find_by_repository_id(id) }

    client = MedusaDownloaderClient.new
    download_url = client.download_url(items, zip_name)

    download.update(url: download_url)

    self.task&.succeeded
  end

end
