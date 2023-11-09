class UpdateItemsFromTsvJob < Job

  QUEUE = Job::Queue::ADMIN

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
    # TODO: remove this
    tsv_dir = File.expand_path("~/tsv_forensics")
    FileUtils.mkdir_p(tsv_dir)
    FileUtils.cp(args[:tsv_pathname], File.join(tsv_dir, args[:tsv_original_filename]))

    ItemUpdater.new.update_from_tsv(args[:tsv_pathname],
                                    args[:tsv_original_filename],
                                    self.task)

    File.delete(args[:tsv_pathname]) if File.exist?(args[:tsv_pathname])

    self.task.succeeded
  end

end
