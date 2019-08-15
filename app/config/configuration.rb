##
# Singleton interface to the application configuration.
#
# Usage:
#
# Configuration.instance.key_name (shorthand for
# Configuration.instance.get(:key_name))
#
class Configuration

  include Singleton

  ##
  # @return [Object]
  #
  def get(key)
    cfset = ENV.fetch("RAILS_CONFIGSET") { Rails.env }
    Rails.application.credentials.dig(cfset.to_sym, key.to_sym)
  end

  def method_missing(m, *args, &block)
    self.respond_to?(m) ? super : get(m)
  end

end
