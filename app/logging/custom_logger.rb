##
# Singleton logging class. All application log messages should be logged using
# this.
#
class CustomLogger

  include Singleton

  def debug(msg)
    Rails.logger.debug(msg)
  end

  def error(msg)
    Rails.logger.error(msg)
  end

  def info(msg)
    Rails.logger.info(msg)
  end

  def warn(msg)
    Rails.logger.warn(msg)
  end

end