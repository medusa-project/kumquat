require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kumquat
  class Application < Rails::Application

    attr_accessor :shibboleth_host

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Make pages embeddable within other websites. (Spurlock needs this as of
    # 8/2017.)
    config.action_dispatch.default_headers =
        config.action_dispatch.default_headers.delete('X-Frame-Options')

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
