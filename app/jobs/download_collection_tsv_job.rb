class DownloadCollectionTsvJob < Job

  LOGGER = CustomLogger.new(DownloadCollectionTsvJob)
  QUEUE  = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array with [Collection] instance at
  #                     position 0, [Download] instance at position 1, and
  #                     boolean ("only undescribed") at position 2.
  # @raises [ArgumentError]
  #
  def perform(*args)
    collection       = args[0]
    download         = args[1]
    only_undescribed = args[2]

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
