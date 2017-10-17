class ReplaceItemMetadataJob < Job

  queue_as :default

  ##
  # @param args [Array] Six-element array. Position 0 contains either a
  #                     Collection UUID, an ItemSet ID, or an Enumerable of
  #                     Item UUIDs.
  #                     Position 1 contains a matching mode: `exact_match`,
  #                     `contain`, `start`, or end`.
  #                     Position 2 contains the value to find.
  #                     Position 3 contains an element name.
  #                     Position 4 contains the replace mode: `whole_value` or
  #                     `matched_part`.
  #                     Position 5 contains the value to replace with.
  # @raises [ArgumentError]
  #
  def perform(*args)
    if args[0].kind_of?(Collection)
      items = args[0].items
      what = args[0].title
    elsif args[0].kind_of?(ItemSet)
      items = args[0].items
      what = args[0].name
    elsif args[0].respond_to?(:each)
      items = args[0]
      what = "#{args[0].length} items"
    else
      raise ArgumentError, 'Illegal first argument'
    end

    matching_mode = args[1].to_sym
    find_value = args[2]
    element_name = args[3]
    replace_mode = args[4].to_sym
    replace_value = args[5]

    self.task.update(status_text: "Replacing instances of \"#{find_value}\" "\
        "with \"#{replace_value}\" in #{element_name} element in #{what}")

    ItemUpdater.new.replace_element_values(items, matching_mode, find_value,
                                           element_name, replace_mode,
                                           replace_value, self.task)

    self.task.succeeded
  end

end
