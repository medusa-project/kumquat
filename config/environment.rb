# Load the Rails application.
require File.expand_path('../application', __FILE__)

Rails.logger = Logger.new(STDOUT) unless Rails.env.production?

# Initialize the Rails application.
Rails.application.initialize!
