class BatchChangeItemMetadataJob < Job

  QUEUE = :default

  queue_as QUEUE

  ##
  # @param args [Array] Three-element array. Position 0 contains either a
  #                     Collection UUID, an ItemSet ID, or an Enumerable of
  #                     Item UUIDs.
  #                     Position 1 contains an element name. Position 2
  #                     contains an array of replacement values, as hashes with
  #                     :string and :uri keys.
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

    element_name = args[1]
    replace_values = args[2]

    self.task.update!(status_text: "Changing #{element_name} element values "\
        "in #{what}")

    ItemUpdater.new.change_element_values(items, element_name, replace_values,
                                          self.task)

    self.task.succeeded
  end

end
