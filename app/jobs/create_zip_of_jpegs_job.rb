class CreateZipOfJpegsJob < Job

  QUEUE = Job::Queue::PUBLIC

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

    temp_pathname = ZipGenerator.new.generate_zip(items: items,
                                                  include_private_binaries: include_private_binaries,
                                                  task: self.task)

    if temp_pathname.present?
      # Upload the PDF into the application S3 bucket.
      filename = "#{zip_name}-#{Time.now.to_formatted_s(:number)}.zip"
      dest_key = "#{Download::DOWNLOADS_KEY_PREFIX}#{filename}"
      File.open(temp_pathname, "r") do |file|
        KumquatS3Client.instance.put_object(bucket: KumquatS3Client::BUCKET,
                                            key:    dest_key,
                                            body:   file)
      end
      download.update!(filename: filename)

      self.task&.succeeded
    else
      self.task&.fail
    end
  end

end
