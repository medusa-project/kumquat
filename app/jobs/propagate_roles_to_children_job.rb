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

    self.task.status_text = "Propagating effective roles to children of "\
    "#{item.title} in #{item&.collection.title}"

    # Indeterminate because the work happens in a transaction outside of which
    # progress updates wouldn't appear.
    self.task.indeterminate = true
    self.task.save!

    ActiveRecord::Base.transaction do
      item.propagate_roles
    end

    Solr.instance.commit
    self.task.succeeded
  end

end
