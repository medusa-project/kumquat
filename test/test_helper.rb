ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def refresh_elasticsearch
    client = ElasticsearchClient.instance

    index = ElasticsearchIndex.current_index(Agent::ELASTICSEARCH_TYPE)
    client.refresh(index.name)
    index = ElasticsearchIndex.current_index(Collection::ELASTICSEARCH_TYPE)
    client.refresh(index.name)
    index = ElasticsearchIndex.current_index(Item::ELASTICSEARCH_TYPE)
    client.refresh(index.name)
  end

  def setup_elasticsearch
    ElasticsearchIndex.migrate_to_latest
    ElasticsearchClient.instance.recreate_all_indexes
  end

  def sign_in_as(user)
    post '/auth/developer/callback', params: {
        name: user.username, email: "#{user.username}@example.org"
    }
  end

  def sign_out
    delete signout_path
  end

end
