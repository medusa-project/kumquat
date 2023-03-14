class DownloadCollectionTsvJob < Job

  LOGGER = CustomLogger.new(DownloadCollectionTsvJob)
  QUEUE  = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection`: {Collection} instance
  # 3. `:download`: {Download} instance
  # 4. `:only_undescribed`: Boolean
  #
  # @param args [Hash]
  #
  def perform(**args)
    collection       = args[:collection]
    download         = args[:download]
    only_undescribed = args[:only_undescribed]

    self.task.update!(download:      download,
                      indeterminate: true,
                      status_text:   "Generating TSV for #{collection.title}")

    tsv          = ItemTsvExporter.new.items_in_collection(collection,
                                                           only_undescribed: only_undescribed)
    tsv_filename = "#{CGI::escape(collection.title)}-#{Time.now.to_formatted_s(:number)}.tsv"

    KumquatS3Client.instance.put_object(bucket: KumquatS3Client::BUCKET,
                                        key:    Download::DOWNLOADS_KEY_PREFIX + tsv_filename,
                                        body:   StringIO.new(tsv))

    download.update(filename: tsv_filename)
    self.task&.succeeded
  end

end
