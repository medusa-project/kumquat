class PurgeItemsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:collection`: {Collection} instance
  # 2. `:user`: {User} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    collection = args[:collection]

    self.task&.update(status_text: "Purging items in #{collection.title}")

    count = collection.purge

    if self.task
      self.task.status_text += ": purged #{count} items"
      self.task.succeeded
    end
  end

end
