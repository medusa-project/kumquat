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
    Item.uncached do
      items = collection.items
      count = items.count + 1 # plus the collection
      items.find_each.with_index do |item, index|
        item.reindex
        self.task&.progress = (index + 1) / count.to_f
      end
    end

    self.task&.succeeded
  end

end
