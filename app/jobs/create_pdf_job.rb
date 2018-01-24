class CreatePdfJob < Job

  QUEUE = Job::Queue::DOWNLOAD

  queue_as QUEUE

  ##
  # @param args [Array] Two-element array with Item at position 0 and Download
  #                     instance at position 1.
  #
  def perform(*args)
    item = args[0]
    download = args[1]

    self.task&.update!(download: download,
                       status_text: "Generating PDF for #{item}")

    temp_pathname = IiifPdfGenerator.new.generate_pdf(item, self.task)

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
