# Load the Rails application.
require_relative 'application'

Rails.logger = ActiveSupport::Logger.new(STDOUT) if Rails.env.development? or Rails.env.test?

# Initialize the Rails application.
Rails.application.initialize!
