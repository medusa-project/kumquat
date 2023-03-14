##
# Propagates various item properties to its children.
#
class PropagatePropertiesToChildrenJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:item`: {Item} instance
  # 2. `:user`: {User} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    item = args[:item]

    self.task.update(status_text: "Propagating heritable properties of "\
        "#{item.title} to its children ")

    item.propagate_heritable_properties(self.task)

    self.task&.succeeded
  end

end
