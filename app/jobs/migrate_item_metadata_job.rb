class MigrateItemMetadataJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. One of the following:
  #     * `:collection`: {Collection} instance
  #     * `:item_set`: {ItemSet} instance
  #     * `:item_ids`: Array of {Item} UUIDs
  # 3. `source_element`: Element name string
  # 4. `dest_element`: Element name string
  #
  # @param args [Hash]
  # @raises [ArgumentError]
  #
  def perform(**args)
    if args[:collection]
      items = args[:collection].items
      what  = args[:collection].title
    elsif args[:item_set]
      items = args[:item_set].items
      what  = args[:item_set].name
    elsif args[:item_ids]
      items = Item.where(repository_id: args[:item_ids])
      what  = "#{items.count} items"
    else
      raise ArgumentError, 'Illegal first argument'
    end
    source_element = args[:source_element]
    dest_element   = args[:dest_element]

    self.task.update!(status_text: "Migrating #{source_element} "\
                                   "elements to #{dest_element} in #{what}")

    ItemUpdater.new.migrate_elements(items, source_element, dest_element,
                                     self.task)

    self.task.succeeded
  end

end
