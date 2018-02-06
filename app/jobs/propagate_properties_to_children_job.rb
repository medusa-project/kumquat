##
# Propagates various item properties to its children.
#
class PropagatePropertiesToChildrenJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array with item UUID at position 0.
  #
  def perform(*args)
    item = Item.find_by_repository_id(args[0])

    self.task.update(status_text: "Propagating heritable properties of "\
        "#{item.title} to its children ")

    item.propagate_heritable_properties(self.task)

    self.task&.succeeded
  end

end
