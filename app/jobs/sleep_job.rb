##
# A job that sleeps for a given length of time.
#
class SleepJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Enumerable<String>] One-element array containing a sleep
  #                                  interval in seconds.
  #
  def perform(*args)
    interval = args[0].to_i
    self.task&.update!(indeterminate: false,
                       status_text: "Sleeping for #{interval} seconds")

    interval.times do |i|
      self.task&.update!(percent_complete: i / interval.to_f)
      sleep 1
    end

    self.task&.succeeded
  end

end
