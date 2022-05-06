class DownloadZipJob < Job

  QUEUE = Job::Queue::PUBLIC

  queue_as QUEUE

  ##
  # @param args [Array] Four-element array with array of {Item}s at
  #                     position 0, zip name at position 1, whether to include
  #                     private binaries at position 2, and {Download}
  #                     instance at position 3.
  #
  def perform(*args)
    item_ids                 = args[0]
    zip_name                 = args[1]
    include_private_binaries = args[2]
    download                 = args[3]

    self.task&.update!(download: download,
                       indeterminate: true,
                       status_text: "Requesting a #{item_ids.length}-item zip "\
                       "file from the Medusa Downloader")

    items  = Item.where('repository_id IN (?)', item_ids)
    client = MedusaDownloaderClient.new
    download_url = client.download_url(items: items,
                                       zip_name: zip_name,
                                       include_private_binaries: include_private_binaries)
    download.update(url: download_url)

    self.task&.succeeded
  end

end
