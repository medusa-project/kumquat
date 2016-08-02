class SyncCollectionsJob < Job

  queue_as :default

  ##
  # @param args [Hash]
  #
  def perform(*args)
    self.task.status_text = 'Syncing collections'
    self.task.indeterminate = false
    self.task.save!

    MedusaIngester.new.ingest_collections(self.task)
    Solr.instance.commit

    self.task.succeeded
  end

end