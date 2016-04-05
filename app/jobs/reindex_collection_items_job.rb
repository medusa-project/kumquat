class ReindexCollectionItemsJob < Job

  queue_as :default

  ##
  # @param args [Hash]
  #
  def perform(*args)
    self.task.status_text = "Indexing collection: #{col.title}"
    self.task.indeterminate = false
    self.task.save!

    col = MedusaCollection.find(args[0])
    FilesystemIndexer.new.index(col)
    Solr.instance.commit

    self.task.succeeded
  end

end