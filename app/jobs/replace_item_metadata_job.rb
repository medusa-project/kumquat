class ReplaceItemMetadataJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. One of the following:
  #     * `:collection`: {Collection} instance
  #     * `:item_set`: {ItemSet} instance
  #     * `:item_ids`: Array of {Item} UUIDs
  # 2. `:matching_mode`: One of "exact match", "contain", "start", or "end"
  # 3. `:find_value`: Value to find
  # 4. `:element_name`
  # 5. `:replace_mode`: One of "whole_value" or "matched_part"
  # 6. `:replace_value`: Value to replace with
  # 7. `:user`: {User} instance
  #
  # @param args [Hash]
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
      what  = "#{args[:item_ids].length} items"
    else
      raise ArgumentError, 'Illegal first argument'
    end

    matching_mode = args[:matching_mode].to_sym
    find_value    = args[:find_value]
    element_name  = args[:element_name]
    replace_mode  = args[:replace_mode].to_sym
    replace_value = args[:replace_value]

    self.task.update(status_text: "Replacing instances of \"#{find_value}\" "\
        "with \"#{replace_value}\" in #{element_name} element in #{what}")

    ItemUpdater.new.replace_element_values(items, matching_mode, find_value,
                                           element_name, replace_mode,
                                           replace_value, self.task)

    self.task.succeeded
  end

end
