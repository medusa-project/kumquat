##
# Logging class that enhances Rails.logger with string formatting.
#
class CustomLogger

  attr_accessor :class_

  def initialize(class_)
    self.class_ = class_
  end

  ##
  # @param msg [String]
  # @param args [Array] Optional arguments to insert into a call to sprintf().
  #
  def debug(msg, *args)
    Rails.logger.debug(format(msg, *args))
  end

  ##
  # @param msg [String]
  # @param args [Array] Optional arguments to insert into a call to sprintf().
  #
  def info(msg, *args)
    Rails.logger.info(format(msg, *args))
  end

  ##
  # @param msg [String]
  # @param args [Array] Optional arguments to insert into a call to sprintf().
  #
  def warn(msg, *args)
    Rails.logger.warn(format(msg, *args))
  end

  ##
  # @param msg [String]
  # @param args [Array] Optional arguments to insert into a call to sprintf().
  #
  def error(msg, *args)
    Rails.logger.error(format(msg, *args))
  end

  private

  def format(msg, *args)
    io = StringIO.new
    io << class_.to_s
    io << ' '
    msg = sprintf(msg, *args) if args.any?
    io << msg
    io.string
  end

end