##
# Propagates various collection properties to its items.
#
class PropagatePropertiesToItemsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with collection UUID at position 0.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task.update(status_text: "Propagating heritable collection "\
        "properties to items in #{collection.title}")

    collection.propagate_heritable_properties(self.task)

    self.task&.succeeded
  end

end
