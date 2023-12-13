class UpdateItemsFromEmbeddedMetadataJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection`: {Collection} instance
  # 3. `:include_date_created` [Boolean]
  #
  # @param args [Hash]
  #
  def perform(**args)
    self.task.update(status_text:
                       'Updating item metadata from embedded file metadata')
    ItemUpdater.new.update_from_embedded_metadata(collection:           args[:collection],
                                                  include_date_created: args[:include_date_created],
                                                  task:                 self.task)
    self.task.succeeded
  end

end
