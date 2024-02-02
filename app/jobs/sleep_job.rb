##
# A job that sleeps for a given length of time.
#
class SleepJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # Arguments:
  #
  # 1. `:interval`: Sleep interval in seconds
  # 2. `:user`: {User} instance
  #
  # @param args [Hash]
  #
  def perform(**args)
    interval = args[:interval].to_i
    self.task&.update!(indeterminate: false,
                       status_text: "Sleeping for #{interval} seconds")

    interval.times do |i|
      self.task&.update!(percent_complete: i / interval.to_f)
      sleep 1
    end

    self.task&.succeeded
  end

end
