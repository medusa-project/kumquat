ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def refresh_opensearch
    OpensearchClient.instance.refresh
  end

  def setup_opensearch
    index  = Configuration.instance.opensearch_index
    client = OpensearchClient.instance
    client.delete_index(index) if client.index_exists?(index)
    client.create_index(index)
  end

  def sign_in_as(user)
    username = user.kind_of?(User) ? user.username : user
    post '/auth/developer/callback', params: {
      name: username, email: "#{username}@example.org"
    }
  end

  def sign_out
    delete signout_path
  end

end
