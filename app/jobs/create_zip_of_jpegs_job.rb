class CreateZipOfJpegsJob < Job

  QUEUE = Job::Queue::DOWNLOAD

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array with array of Items at
  #                     position 0, zip name at position 1, and Download
  #                     instance at position 2.
  #
  def perform(*args)
    item_ids = args[0]
    zip_name = args[1]
    download = args[2]

    self.task&.update!(download: download,
                       status_text: "Converting JPEGs for #{item_ids.length} items")

    items     = item_ids.map { |id| Item.find_by_repository_id(id) }
    converter = IiifImageConverter.new

    Dir.mktmpdir do |tmpdir|
      items.each do |item|
        converter.convert_images(item, tmpdir, :jpg, self.task)
      end

      # Create the downloads directory if it doesn't exist.
      zip_dir = Download::DOWNLOADS_DIRECTORY
      FileUtils.mkdir_p(zip_dir)

      # Create the zip file within the downloads directory.
      zip_filename = "#{zip_name}-#{Time.now.to_formatted_s(:number)}.zip"
      zip_pathname = File.join(zip_dir, zip_filename)

      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr "#{zip_pathname}" #{tmpdir}`

      download.update(filename: zip_filename)
      self.task&.succeeded
    end
  end

end
