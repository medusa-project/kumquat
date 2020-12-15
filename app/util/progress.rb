##
# Prints the progress of a long-running task to the console.
#
# The task must be of known length (obviously), and nothing else should print
# to the console while reporting is in progress.
#
# # Usage
#
# ```
# arr = ["a", "b", "c"]
# p = Progress.new(arr.length)
#
# arr.each.with_index do |element, index|
#   p.report(index, "Doing something")
# end
# ```
#
class Progress

  DATE_FORMAT = "%-m/%d %l:%M %p"

  ##
  # @param count [Integer] Number of iterations needed to reach completion.
  #
  def initialize(count)
    @start_time = Time.now
    @count      = count
  end

  ##
  # @param iteration [Integer] Zero-based iteration index.
  # @param message [String]
  # @return [void]
  #
  def report(iteration, message)
    return if Rails.env.test?
    str = "#{message}: #{progress_str(iteration)}"
    str = str.ljust(80)
    print "#{str}\r"
    print "\n" if iteration >= @count
  end

  private

  ##
  # @param iteration [Integer]
  # @return [String] Progress string.
  #
  def progress_str(iteration)
    pct         = iteration / @count.to_f
    pct_str     = "#{(pct * 100).round(2)}%".ljust(6, " ")
    eta         = TimeUtils.eta(@start_time, pct)
    remaining_i = eta.to_i - Time.now.to_i
    remaining_s = TimeUtils.seconds_to_hms(remaining_i)
    "#{pct_str} [#{remaining_s} remaining]"
  end

end
