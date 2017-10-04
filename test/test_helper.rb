ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def sign_in_as(user)
    post '/auth/developer/callback', params: {
        name: user.username, email: "#{user.username}@example.org"
    }
  end

  def sign_out
    delete signout_path
  end

end
