class ReindexItemsJob < Job

  QUEUE = :default

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with Collection whose items to reindex
  #                     at position 0.
  #
  def perform(*args)
    collection = args[0]

    self.task&.update(status_text: "Reindexing items in #{collection.title}")

    collection.items.each do |item|
      item.reindex
    end

    self.task&.succeeded
  end

end
