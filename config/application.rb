require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PearTree
  class Application < Rails::Application

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.active_job.queue_adapter = :delayed_job

    # Enables dynamic error pages.
    config.exceptions_app = self.routes

    # Make pages embeddable within other websites. (Spurlock needs this as of
    # 8/2017.)
    config.action_dispatch.default_headers =
        config.action_dispatch.default_headers.delete('X-Frame-Options')
  end
end
