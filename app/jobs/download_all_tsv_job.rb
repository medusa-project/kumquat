class DownloadAllTsvJob < Job

  DESTINATION_DIR = Download::DOWNLOADS_DIRECTORY

  queue_as :download

  ##
  # @param args [Array] One-element array with Download instance at position 0.
  # @raises [ArgumentError]
  #
  def perform(*args)
    download = args[0]

    self.task.update!(download: download,
                      status_text: 'Generating TSV for all collections')

    Dir.mktmpdir do |tmpdir|
      collections = Collection.all.select{ |c| c.num_items > 0 }
      collections.each_with_index do |col, index|
        tsv_filename = "#{CGI::escape(col.title)}.tsv"
        tsv_file = File.join(tmpdir, tsv_filename)

        CustomLogger.instance.info(
            "DownloadAllTsvJob.perform(): generating #{tsv_file} "\
            "(#{(self.task.percent_complete * 100).round(2)}%)")
        File.open(tsv_file, 'w') { |file| file.write(col.items_as_tsv) }

        self.task.progress = index / collections.length.to_f
      end

      # Create the downloads directory if it doesn't exist.
      FileUtils.mkdir_p(DESTINATION_DIR)

      if Dir.exists?(DESTINATION_DIR)
        # Create the zip file within the downloads directory.
        zip_filename = "tsv-#{download.key}.zip"
        zip_pathname = File.join(DESTINATION_DIR, zip_filename)

        CustomLogger.instance.info("DownloadAllTsvJob.perform(): "\
          "creating zip: #{zip_pathname}")

        # -j: don't record directory names
        # -r: recurse into directories
        `zip -jr #{zip_pathname} #{tmpdir}`

        if File.exists?(zip_pathname)
          download.update(filename: zip_filename)
          self.task&.succeeded
        else
          raise IOError, "File does not exist: #{zip_pathname}"
        end
      else
        raise IOError, "Unable to create directory: #{DESTINATION_DIR}"
      end
    end
  end

end
