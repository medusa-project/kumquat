class SyncCollectionsJob < Job

  queue_as :default

  ##
  # @param args [Hash]
  #
  def perform(*args)
    self.task.update!(status_text: 'Syncing collections')

    MedusaIngester.new.ingest_collections(self.task)
    Solr.instance.commit

    self.task.succeeded
  end

end