ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def refresh_elasticsearch
    client = ElasticsearchClient.instance
    client.refresh(Configuration.instance.elasticsearch_index)
  end

  def setup_elasticsearch
    index = Configuration.instance.elasticsearch_index
    client = ElasticsearchClient.instance
    client.delete_index(index, false)
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
