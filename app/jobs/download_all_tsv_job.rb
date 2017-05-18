class DownloadAllTsvJob < Job

  queue_as :download

  ##
  # @param args [Array] One-element array with Download instance ID at position
  #                     0.
  # @raises [ArgumentError]
  #
  def perform(*args)
    self.task.update!(status_text: 'Generating TSV for all collections')
    download = args[0]

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
        download.update(percent_complete: self.task.percent_complete)
      end

      # Create the downloads directory if it doesn't exist.
      zip_dir = File.join(Rails.root, 'tmp', 'downloads')
      FileUtils.mkdir_p(zip_dir)
      # Create the zip file within the downloads directory.
      zip_filename = "tsv-#{Time.now.to_formatted_s(:number)}.zip"
      zip_pathname = File.join(zip_dir, zip_filename)
      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr #{zip_pathname} #{tmpdir}`

      download.update(filename: zip_filename, percent_complete: 1,
                      status: Download::Status::READY)
    end

    self.task.succeeded
  end

end
