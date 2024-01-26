class CreateZipOfJpegsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:item_ids`: Array of {Item} UUIDs
  # 3. `:zip_name`
  # 4. `:include_private_binaries`
  # 5. `:download`: {Download} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    item_ids                 = args[:item_ids]
    zip_name                 = args[:zip_name]
    include_private_binaries = args[:include_private_binaries]
    download                 = args[:download]

    self.task&.update!(download:    download,
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
