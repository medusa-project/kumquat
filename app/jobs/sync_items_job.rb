class SyncItemsJob < Job

  QUEUE = :default

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array with the UUID of the collection to
  #                     sync at position 0; one of the
  #                     MedusaIngester::IngestMode constants at position 1;
  #                     and options hash at position 2.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task.update(status_text: "Importing items in #{collection.title}")

    result = MedusaIngester.new.sync_items(collection, args[1], args[2],
                                           self.task)

    self.task.status_text += ": #{result[:num_created].to_i} created; "\
        "#{result[:num_updated].to_i} updated; "\
        "#{result[:num_deleted].to_i} deleted; "\
        "#{result[:num_skipped].to_i} skipped"
    self.task.succeeded
  end

end
