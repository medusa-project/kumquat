class CreatePdfJob < Job

  QUEUE = Job::Queue::PUBLIC

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:item`: {Item} instance
  # 3. `:include_private_binaries`: Boolean
  # 4. `:download`: {Download} instance.
  #
  # @param args [Hash]
  #
  def perform(**args)
    item                     = args[:item]
    include_private_binaries = args[:include_private_binaries]
    download                 = args[:download]

    self.task&.update!(download:    download,
                       status_text: "Generating PDF for #{item}")

    temp_pathname = PdfGenerator.new.generate_pdf(item: item,
                                                  include_private_binaries: include_private_binaries,
                                                  task: self.task)
    if temp_pathname.present?
      # Upload the PDF into the application S3 bucket.
      filename = "item-#{Time.now.to_formatted_s(:number)}.pdf"
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
