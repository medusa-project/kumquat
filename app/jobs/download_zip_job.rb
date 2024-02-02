class DownloadZipJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:item_ids`: Array of {Item} UUIDs
  # 3. `:zip_name`
  # 4. `:include_private_binaries`: Boolean
  # 5. `:download`: {Download} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    item_ids                 = args[:item_ids]
    zip_name                 = args[:zip_name]
    include_private_binaries = args[:include_private_binaries]
    download                 = args[:download]

    self.task&.update!(download:      download,
                       indeterminate: true,
                       status_text:   "Requesting a #{item_ids.length}-item "\
                                      "zip file from the Medusa Downloader")

    items  = Item.where('repository_id IN (?)', item_ids)
    client = MedusaDownloaderClient.new
    download_url = client.download_url(items: items,
                                       zip_name: zip_name,
                                       include_private_binaries: include_private_binaries)
    download.update(url: download_url)

    self.task&.succeeded
  end

end
