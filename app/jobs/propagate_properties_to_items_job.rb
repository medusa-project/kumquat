##
# Propagates various collection properties to its items.
#
class PropagatePropertiesToItemsJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:collection`: {Collection} instance
  # 2. `:user`: {User} instance
  #
  def perform(**args)
    collection = args[:collection]

    self.task.update(status_text: "Propagating heritable collection "\
        "properties to items in #{collection.title}")

    collection.propagate_heritable_properties(self.task)

    self.task&.succeeded
  end

end
