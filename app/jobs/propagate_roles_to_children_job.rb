##
# Propagates roles from an item to its children.
#
class PropagateRolesToChildrenJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array with collection UUID at position 0.
  #
  def perform(*args)
    item = Item.find_by_repository_id(args[0])

    self.task.update(status_text: "Propagating effective roles to children "\
        "of #{item.title} in #{item&.collection.title}")

    item.propagate_roles(self.task)

    Solr.instance.commit
    self.task.succeeded
  end

end
