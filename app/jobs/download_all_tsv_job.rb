class DownloadAllTsvJob < Job

  LOGGER          = CustomLogger.new(DownloadAllTsvJob)
  QUEUE           = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with Download instance at position 0.
  # @raises [ArgumentError]
  #
  def perform(*args)
    download = args[0]

    self.task.update!(download:    download,
                      status_text: 'Generating TSV for all collections')

    Dir.mktmpdir do |tmpdir|
      # Write each collection's TSV to a separate file within the temp
      # directory.
      collections = Collection.all.select{ |c| c.num_items > 0 }
      collections.each_with_index do |col, index|
        tsv_filename = "#{CGI::escape(col.title)}.tsv"
        tsv_pathname = File.join(tmpdir, tsv_filename)

        LOGGER.debug("perform(): generating %s (%.2f%%)",
                     tsv_pathname,
                     self.task.percent_complete * 100)
        File.open(tsv_pathname, 'w') do |file|
          file.write(ItemTsvExporter.new.items_in_collection(col))
        end

        self.task.progress = index / collections.length.to_f
      end

      # Create the zip file within the temp directory.
      zip_filename = "all_collections_tsv-#{Time.now.to_formatted_s(:number)}.zip"
      zip_pathname = File.join(tmpdir, zip_filename)

      LOGGER.debug('perform(): creating zip: %s', zip_pathname)

      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr "#{zip_pathname}" "#{tmpdir}"`

      if File.exists?(zip_pathname)
        dest_key = Download::DOWNLOADS_KEY_PREFIX + zip_filename
        File.open(zip_pathname, "r") do |file|
          KumquatS3Client.instance.put_object(bucket: KumquatS3Client::BUCKET,
                                              key:    dest_key,
                                              body:   file)
        end
        download.update(filename: zip_filename)
        self.task&.succeeded
      else
        raise IOError, "File does not exist: #{zip_pathname}"
      end
    end
  end

end
