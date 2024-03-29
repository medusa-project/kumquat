class UpdateItemsFromTsvJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:tsv_pathname`
  # 3. `:tsv_original_filename`
  #
  # @param args [Hash]
  #
  def perform(**args)
    self.task.update(status_text: 'Updating item metadata from TSV')

    ItemUpdater.new.update_from_tsv(args[:tsv_pathname],
                                    args[:tsv_original_filename],
                                    self.task)

    File.delete(args[:tsv_pathname]) if File.exist?(args[:tsv_pathname])

    self.task.succeeded
  end

end
