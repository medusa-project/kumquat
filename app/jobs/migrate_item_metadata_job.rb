class MigrateItemMetadataJob < Job

  QUEUE = :default

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array. Position 0 contains either a
  #                     Collection UUID, an ItemSet ID, or an Enumerable of
  #                     Item UUIDs.
  #                     Position 1 contains a source element name. Position 2
  #                     contains a destination element name.
  # @raises [ArgumentError]
  #
  def perform(*args)
    if args[0].is_a?(Collection)
      items = args[0].items
      what = args[0].title
    elsif args[0].is_a?(ItemSet)
      items = args[0].items
      what = args[0].name
    elsif args[0].respond_to?(:each)
      items = args[0]
      what = "#{args[0].length} items"
    else
      raise ArgumentError, 'Illegal first argument'
    end

    source_element = args[1]
    dest_element = args[2]

    self.task.update!(status_text: "Migrating #{source_element} "\
      "elements to #{dest_element} in #{what}")

    ItemUpdater.new.migrate_elements(items, source_element, dest_element,
                                     self.task)

    self.task.succeeded
  end

end
