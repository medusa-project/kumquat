##
# Singleton interface to the application configuration (/config/kumquat.yml).
#
# Usage:
#
# Configuration.instance.key_name (shorthand for
# Configuration.instance.get(:key_name))
#
class Configuration

  include Singleton

  def initialize
    raw_config = File.read(File.join(Rails.root, 'config', 'kumquat.yml'))
    @config = YAML.load(raw_config)[Rails.env]
  end

  ##
  # @return [Object]
  #
  def get(key)
    @config[key.to_sym]
  end

  def method_missing(m, *args, &block)
    self.respond_to?(m) ? super : get(m)
  end

end
