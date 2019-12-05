##
# Singleton interface to the application configuration.
#
# Going back to its inception, Rails has offered a half dozen or more ways of
# supporting application-specific configuration. The application configuration
# system is designed with the following goals:
#
# 1. Consolidate configuration into as few files as possible for ease of use.
# 2. Require as little custom code as possible.
# 3. Centralize configuration of all environments so that adding & removing
#    keys is quick and painless.
#
# The configuration system works in two different ways depending on the Rails
# environment:
#
# 1. In the development and test environments, there are unencrypted
#    YAML configuration files in the `config/credentials` directory. These can
#    be edited normally and are **not** committed to version control.
# 2. The demo and production environments utilize the "multi-environment
#    credentials" system introduced in Rails 6. There are separate encrypted
#    demo and production files and accompanying master keys. (The `.enc` files
#    are committed to version control but the `.key` files are not.) To edit,
#    use `rails credentials:edit -e <demo or production>`.
#
# This class abstracts all of the above.
#
# # Usage
#
# `Configuration.instance.key_name` (shorthand for
# `Configuration.instance.get(:key_name)`)
#
class Configuration

  include Singleton

  ##
  # @param key [String]
  # @return [Object]
  #
  def get(key)
    if Rails.env.development? or Rails.env.test?
      read_unencrypted_config
      return @config[key.to_sym]
    end
    Rails.application.credentials.dig(key)
  end

  def method_missing(m, *args, &block)
    self.respond_to?(m) ? super : get(m)
  end

  private

  def read_unencrypted_config
    unless @config
      raw_config = File.read(File.join(
          Rails.root, 'config', 'credentials', "#{Rails.env}.yml"))
      @config = YAML.load(raw_config).with_indifferent_access
    end
  end

end
