class ReindexJob < Job

  queue_as :default

  ##
  # @param args [Hash]
  # @option args [String] :pathname Pathname to index
  #
  def perform(*args)
    self.task.status_text = 'Reindexing repository'
    self.task.indeterminate = true

    Indexer.new.index_all(args[0][:pathname])
    Solr.instance.commit

    self.task.succeeded
  end

end