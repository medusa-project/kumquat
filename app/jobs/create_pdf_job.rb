class CreatePdfJob < Job

  QUEUE = Job::Queue::PUBLIC

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array with [Item] at position 0, whether
  #                     to include private binaries at position 1, and
  #                     [Download] instance at position 2.
  #
  def perform(*args)
    item                     = args[0]
    include_private_binaries = args[1]
    download                 = args[2]

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
