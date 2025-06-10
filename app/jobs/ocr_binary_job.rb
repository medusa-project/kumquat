##
# Runs OCR against a single binary.
#
# @see OcrCollectionJob
# @see OcrItemJob
#
class OcrBinaryJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:binary` {Binary} to run OCR on
  # 3. `:language_code`: ISO 639-2 language code
  #
  # @param args [Hash]
  #
  def perform(**args)
    binary = args[:binary]

    self.task&.update(status_text: "Running OCR on #{binary.object_key}")

    binary.detect_text(language: args[:language_code])
    binary.ocred_at = Time.current 
    binary.save!
    binary.item.reindex
    binary.item.update!(ocred: true)

    self.task&.succeeded
  end

end
