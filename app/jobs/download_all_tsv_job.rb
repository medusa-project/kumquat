class DownloadAllTsvJob < Job

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

        # Update the progress on both the job's task and the download.
        self.task.progress = index / collections.length.to_f
      end

      # Create the downloads directory if it doesn't exist.
      zip_dir = Download::DOWNLOADS_DIRECTORY
      FileUtils.mkdir_p(zip_dir)
      # Create the zip file within the downloads directory.
      zip_filename = "tsv-#{Time.now.to_formatted_s(:number)}.zip"
      zip_pathname = File.join(zip_dir, zip_filename)
      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr #{zip_pathname} #{tmpdir}`

      download.update(filename: zip_filename)
      self.task&.succeeded
    end
  end

end
