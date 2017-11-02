class UnpublishItemsJob < Job

  queue_as :default

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
