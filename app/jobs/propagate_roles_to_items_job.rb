##
# Propagates roles from a collection to its items.
#
class PropagateRolesToItemsJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array with collection UUID at position 0.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task.update(status_text: "Propagating effective roles to items in "\
        "#{collection.title}")

    collection.propagate_roles(self.task)

    Solr.instance.commit
    self.task.succeeded
  end

end
