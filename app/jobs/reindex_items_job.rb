class ReindexItemsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with Collection whose items to reindex
  #                     at position 0.
  #
  def perform(*args)
    collection = args[0]

    self.task&.update(status_text: "Reindexing items in #{collection.title}")

    # Technically the items' owning collection is not an item, but as this job
    # may be invoked in response to metadata profile changes which also affect
    # the collection, we might as well reindex it too.
    collection.reindex
    collection.items.each do |item|
      item.reindex
    end

    self.task&.succeeded
  end

end
