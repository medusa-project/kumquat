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

    self.task.status_text = "Propagating effective roles to items in "\
    "#{collection.title}"

    # Indeterminate because the work happens in a transaction outside of which
    # progress updates wouldn't appear.
    self.task.indeterminate = true
    self.task.save!

    ActiveRecord::Base.transaction do
      collection.propagate_roles
    end

    Solr.instance.commit
    self.task.succeeded
  end

end
