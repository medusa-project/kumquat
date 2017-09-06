# Load the Rails application.
require_relative 'application'

Rails.logger = ActiveSupport::Logger.new(STDOUT) unless Rails.env.production?

# Initialize the Rails application.
Rails.application.initialize!
