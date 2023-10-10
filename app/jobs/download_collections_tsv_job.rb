class DownloadCollectionsTsvJob < Job

  LOGGER = CustomLogger.new(DownloadCollectionsTsvJob)
  QUEUE  = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection_ids`: Array of {Collection} UUIDs.
  # 3. `:download`: {Download} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    collection_ids = args[:collection_ids]
    download       = args[:download]
    user           = args[:user]

    self.task.update!(download:      download,
                      user:          user,
                      indeterminate: true,
                      status_text:   "Generating TSV for "\
                                     "#{collection_ids.length} collections")

    tsv          = CollectionTsvExporter.new.collections(collection_ids)
    tsv_filename = "collections-#{Time.now.to_formatted_s(:number)}.tsv"

    KumquatS3Client.instance.put_object(bucket: KumquatS3Client::BUCKET,
                                        key:    Download::DOWNLOADS_KEY_PREFIX + tsv_filename,
                                        body:   StringIO.new(tsv))

    download.update(filename: tsv_filename)
    self.task&.succeeded
  end

end
