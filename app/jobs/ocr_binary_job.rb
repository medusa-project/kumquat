##
# Runs OCR against a single binary.
#
# @see [OcrCollectionJob]
# @see [OcrItemJob]
#
class OcrBinaryJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] Two-element array containing the ID of the binary to
  #                     run OCR on at position 0, and an ISO 639-2 language
  #                     code at position 1.
  #
  def perform(*args)
    binary = Binary.find(args[0])

    self.task&.update(status_text: "Running OCR on #{binary.object_key}")

    binary.detect_text(language: args[1])
    binary.save!
    binary.item.reindex

    self.task&.succeeded
  end

end
