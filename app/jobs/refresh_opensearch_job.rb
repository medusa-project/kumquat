class RefreshOpensearchJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Empty hash.
  #
  def perform(**args)
    # TODO: don't create a Task
    self.task&.update(status_text: "Refreshing OpenSearch")
    OpensearchClient.instance.refresh
    self.task&.succeeded
  end

end
