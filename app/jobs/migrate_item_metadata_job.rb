class MigrateItemMetadataJob < Job

  queue_as :default

  ##
  # @param args [Array] Three-element array with collection UUID at position 0;
  #                     source element name at position 1; and destination
  #                     element name at position 2.
  # @raises [ArgumentError]
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])
    source_element = args[1]
    dest_element = args[2]

    self.task.status_text = "Migrating \"#{source_element}\" elements to "\
      "\"#{dest_element}\" in #{collection.title}"

    # Indeterminate because the task happens in a transaction from which
    # progress updates won't appear.
    self.task.indeterminate = true
    self.task.save!

    collection.migrate_item_elements(source_element, dest_element)

    Solr.instance.commit
    self.task.succeeded
  end

end
