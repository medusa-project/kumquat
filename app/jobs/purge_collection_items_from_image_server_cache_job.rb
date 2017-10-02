class PurgeCollectionItemsFromImageServerCacheJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array with collection UUID at position 0.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task.update(status_text: "Purging images relating to "\
        "#{collection.title} from the image server cache")

    ImageServer.instance.purge_collection_item_images_from_cache(collection,
                                                                 self.task)
  end

end
