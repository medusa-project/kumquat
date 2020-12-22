class CreateZipOfJpegsJob < Job

  QUEUE = Job::Queue::DOWNLOAD

  queue_as QUEUE

  ##
  # @param args [Enumerable<String>] Four-element array with array of {Item}
  #                                  IDs at position 0, zip name at position 1,
  #                                  whether to include private binaries at
  #                                  position 2, and Download instance at
  #                                  position 3.
  #
  def perform(*args)
    item_ids                 = args[0]
    zip_name                 = args[1]
    include_private_binaries = args[2]
    download                 = args[3]

    self.task&.update!(download: download,
                       status_text: "Converting JPEGs for #{item_ids.length} items")

    items     = Item.where('repository_id IN (?)', item_ids)
    converter = IiifImageConverter.new

    Dir.mktmpdir do |tmpdir|
      Item.uncached do
        items.find_each do |item|
          converter.convert_images(item:                     item,
                                   directory:                tmpdir,
                                   format:                   :jpg,
                                   include_private_binaries: include_private_binaries,
                                   task:                     self.task)
        end
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
