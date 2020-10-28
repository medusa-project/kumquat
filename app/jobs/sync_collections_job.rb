class SyncCollectionsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash]
  #
  def perform(*args)
    self.task.update!(status_text: 'Indexing collections metadata from Medusa')

    MedusaIngester.new.sync_collections(self.task)

    self.task.succeeded
  end

end