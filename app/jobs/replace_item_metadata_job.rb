class ReplaceItemMetadataJob < Job

  queue_as :default

  ##
  # @param args [Array] Six-element array with collection UUID at position 0;
  #                     matching mode (`exact_match`, `contain`, `start`, or
  #                     `end`) at position 1; value to find at position 2;
  #                     element name at position 3; replace mode (`whole_value`
  #                     or `matched_part`) at position 4; and value to replace
  #                     with at position 5.
  # @raises [ArgumentError]
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    matching_mode = args[1].to_sym
    find_value = args[2]
    element_name = args[3]
    replace_mode = args[4].to_sym
    replace_value = args[5]

    if self.task
      self.task.status_text = "Replacing instances of \"#{find_value}\" with "\
        "\"#{replace_value}\" in #{element_name} element in #{collection.title}"

      # Indeterminate because the task happens in a transaction from which
      # progress updates won't appear.
      self.task.indeterminate = true
      self.task.save!
    end

    collection.replace_item_element_values(matching_mode, find_value,
                                           element_name, replace_mode,
                                           replace_value)

    Solr.instance.commit
    self.task&.succeeded
  end

end
