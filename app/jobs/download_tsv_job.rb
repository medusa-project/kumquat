class DownloadTsvJob < Job

  queue_as :download

  ##
  # @param args [Array] Three-element array with Collection instance at
  #                     position 0, Download instance at position 1, and
  #                     boolean ("only undescribed") at position 2.
  # @raises [ArgumentError]
  #
  def perform(*args)
    collection = args[0]
    download = args[1]
    only_undescribed = args[2]

    self.task.update!(download: download,
                      indeterminate: true,
                      status_text: "Generating TSV for #{collection.title}")

    Dir.mktmpdir do |tmpdir|
      tsv_filename = "#{CGI::escape(collection.title)}-#{Time.now.to_formatted_s(:number)}.tsv"
      tsv_pathname = File.join(tmpdir, tsv_filename)

      CustomLogger.instance.info(
          "DownloadTsvJob.perform(): generating #{tsv_pathname}")

      exporter = ItemTsvExporter.new
      File.open(tsv_pathname, 'w') do |file|
        file.write(exporter.items_in_collection(collection,
                                                only_undescribed: only_undescribed))
      end

      # Create the downloads directory if it doesn't exist.
      dl_dir = Download::DOWNLOADS_DIRECTORY
      FileUtils.mkdir_p(dl_dir)

      # Move the TSV file into the downloads directory.
      FileUtils.move(tsv_pathname, dl_dir)

      download.update(filename: tsv_filename)
      self.task&.succeeded
    end
  end

end
