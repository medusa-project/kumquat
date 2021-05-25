class CreatePdfJob < Job

  QUEUE = Job::Queue::DOWNLOAD

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array with {Item} at position 0, whether
  #                     to include private binaries at position 1, and
  #                     {Download} instance at position 2.
  #
  def perform(*args)
    item                     = args[0]
    include_private_binaries = args[1]
    download                 = args[2]

    self.task&.update!(download: download,
                       status_text: "Generating PDF for #{item}")

    temp_pathname = PdfGenerator.new.generate_pdf(item: item,
                                                  include_private_binaries: include_private_binaries,
                                                  task: self.task)

    if temp_pathname.present?
      # Create the downloads directory if it doesn't exist, and move the PDF
      # there.
      dest_dir = Download::DOWNLOADS_DIRECTORY
      FileUtils.mkdir_p(dest_dir)

      dest_pathname = File.join(dest_dir, "item-#{Time.now.to_formatted_s(:number)}.pdf")
      FileUtils.move(temp_pathname, dest_pathname)

      download.update!(filename: File.basename(dest_pathname))

      self.task&.succeeded
    else
      self.task&.fail
    end
  end

end
