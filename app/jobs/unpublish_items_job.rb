class UnpublishItemsJob < Job

  QUEUE = :default

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with an Enumerable of Items at
  #                     position 0.
  # @raises [ArgumentError]
  #
  def perform(*args)
    items = args[0]

    self.task.update!(status_text: "Unpublishing #{items.length} items")

    items.each do |item|
      item.update!(published: false)
    end

    self.task.succeeded
  end

end
