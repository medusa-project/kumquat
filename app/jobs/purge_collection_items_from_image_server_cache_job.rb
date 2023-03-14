class PurgeCollectionItemsFromImageServerCacheJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection`: {Collection} instance
  #
  def perform(**args)
    collection = args[:collection]

    self.task.update(status_text: "Purging images relating to "\
                     "#{collection.title} from the image server cache")

    ImageServer.instance.purge_collection_item_images_from_cache(collection,
                                                                 self.task)
  end

end
