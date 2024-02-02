class BatchChangeItemMetadataJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance.
  # 2. One of the following:
  #     * `:collection`: {Collection} instance
  #     * `:item_set`: {ItemSet} instance
  #     * `:item_ids`: Array of {Item} UUIDs
  # 3. `:element_name`
  # 4. `:replacement_values`: Array of replacement values as
  #    hashes with `:string` and `:uri` keys.
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
      items = Item.where("repository_id IN (?)", args[:item_ids])
      what  = "#{args[:item_ids].length} items"
    else
      raise ArgumentError, 'Illegal first argument'
    end
    element_name   = args[:element_name]
    replace_values = args[:replacement_values]

    self.task.update!(status_text: "Changing #{element_name} element values "\
        "in #{what}")

    ItemUpdater.new.change_element_values(items, element_name, replace_values,
                                          self.task)

    self.task.succeeded
  end

end
