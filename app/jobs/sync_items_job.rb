class SyncItemsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection`: {Collection} instance
  # 3. `:ingest_mode`: One of the {MedusaIngester::IngestMode} constant values
  # 4. `:options`: Options hash
  #
  # @param args [Hash]
  #
  def perform(**args)
    collection = args[:collection]

    self.task.update(status_text: "Importing items in #{collection.title}")

    result = MedusaIngester.new.sync_items(collection, args[:ingest_mode],
                                           args[:options], self.task)

    self.task.status_text += ": #{result[:num_created].to_i} created; "\
        "#{result[:num_updated].to_i} updated; "\
        "#{result[:num_deleted].to_i} deleted; "\
        "#{result[:num_skipped].to_i} skipped"
    self.task.succeeded
  end

end
