class ReindexCollectionItemsJob < Job

  queue_as :default

  ##
  # @param args [Hash]
  #
  def perform(*args)
    col = MedusaCollection.find(args[0])

    self.task.status_text = "Indexing collection: #{col.title}"
    self.task.indeterminate = false
    self.task.save!

    FilesystemIndexer.new.index(col)
    Solr.instance.commit

    self.task.succeeded
  end

end