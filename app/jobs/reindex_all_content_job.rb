class ReindexAllContentJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] Empty array.
  #
  def perform(*args)
    self.task&.update(status_text: 'Reindexing all agents')
    Agent.reindex_all

    self.task&.update(status_text: 'Reindexing all collections')
    Collection.reindex_all

    self.task&.update(status_text: 'Reindexing all items in all collections')
    Item.reindex_all

    self.task&.succeeded
  end

end
