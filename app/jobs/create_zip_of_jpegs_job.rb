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

    items = Item.where('repository_id IN (?)', item_ids)

    temp_pathname = IiifZipGenerator.new.generate_zip(items: items,
                                                      include_private_binaries: include_private_binaries,
                                                      task: self.task)

    if temp_pathname.present?
      # Create the downloads directory if necessary, and move the zip there.
      dest_dir = Download::DOWNLOADS_DIRECTORY
      FileUtils.mkdir_p(dest_dir)

      dest_pathname = File.join(dest_dir, "#{zip_name}-#{Time.now.to_formatted_s(:number)}.zip")
      FileUtils.move(temp_pathname, dest_pathname)

      download.update!(filename: File.basename(dest_pathname))

      self.task&.succeeded
    else
      self.task&.fail
    end
  end

end
