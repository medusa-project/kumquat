ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  ##
  # Seeds a test Solr instance with fixture data.
  #
  def seed_repository
    Solr.instance.purge
    # TODO: fix this
    #FilesystemIndexer.new.index(__dir__ + '/fixtures/repository')
    Solr.instance.commit
  end

end
